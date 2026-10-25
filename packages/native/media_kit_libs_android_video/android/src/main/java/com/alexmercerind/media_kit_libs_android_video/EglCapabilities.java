package com.alexmercerind.media_kit_libs_android_video;

import android.annotation.TargetApi;
import android.opengl.EGL14;
import android.opengl.EGLConfig;
import android.opengl.EGLContext;
import android.opengl.EGLDisplay;

import java.util.HashMap;
import java.util.Map;

/** Tests context creation without changing the Flutter renderer or GPU mode. */
@TargetApi(17)
final class EglCapabilities {
    private static Map<String, Object> cached;
    private static final int EGL_CONTEXT_FLAGS_KHR = 0x30fc;
    private static final int EGL_CONTEXT_OPENGL_DEBUG_BIT_KHR = 1;

    static synchronized Map<String, Object> query() {
        if (cached != null) return new HashMap<>(cached);
        Map<String, Object> result = new HashMap<>();
        result.put("needsDebugContext", false);
        try {
            EGLDisplay display = EGL14.eglGetDisplay(EGL14.EGL_DEFAULT_DISPLAY);
            int[] version = new int[2];
            if (!EGL14.eglInitialize(display, version, 0, version, 1)) {
                result.put("probeError", EGL14.eglGetError());
                return result;
            }
            EGLConfig[] configs = new EGLConfig[1];
            int[] count = new int[1];
            int[] attributes = {
                EGL14.EGL_SURFACE_TYPE, EGL14.EGL_WINDOW_BIT,
                EGL14.EGL_RENDERABLE_TYPE, EGL14.EGL_OPENGL_ES2_BIT,
                EGL14.EGL_RED_SIZE, 8, EGL14.EGL_GREEN_SIZE, 8,
                EGL14.EGL_BLUE_SIZE, 8, EGL14.EGL_ALPHA_SIZE, 0,
                EGL14.EGL_NONE
            };
            if (!EGL14.eglChooseConfig(display, attributes, 0, configs, 0, 1, count, 0)
                    || count[0] == 0) {
                result.put("probeError", EGL14.eglGetError());
                return result;
            }
            EGL14.eglBindAPI(EGL14.EGL_OPENGL_ES_API);
            int zeroFlagsError = create(display, configs[0], new int[]{
                EGL14.EGL_CONTEXT_CLIENT_VERSION, 2, EGL_CONTEXT_FLAGS_KHR, 0,
                EGL14.EGL_NONE
            });
            result.put("zeroFlagsError", zeroFlagsError);
            // The pinned mpv requests a zero FLAGS_KHR attribute. Some EGL
            // implementations reject zero but accept both no flags and DEBUG.
            // A DEBUG context is mpv's available workaround; never enable it
            // on drivers which accept the normal request.
            if (zeroFlagsError == EGL14.EGL_BAD_ATTRIBUTE) {
                boolean plain = create(display, configs[0], new int[]{
                    EGL14.EGL_CONTEXT_CLIENT_VERSION, 2, EGL14.EGL_NONE
                }) == EGL14.EGL_SUCCESS;
                boolean debug = create(display, configs[0], new int[]{
                    EGL14.EGL_CONTEXT_CLIENT_VERSION, 2, EGL_CONTEXT_FLAGS_KHR,
                    EGL_CONTEXT_OPENGL_DEBUG_BIT_KHR, EGL14.EGL_NONE
                }) == EGL14.EGL_SUCCESS;
                result.put("plainContextSupported", plain);
                result.put("debugContextSupported", debug);
                result.put("needsDebugContext", plain && debug);
            }
            cached = new HashMap<>(result);
        } catch (RuntimeException | LinkageError error) {
            result.put("probeError", error.getClass().getSimpleName());
        } finally {
            // This runs on a dedicated thread. Do not eglTerminate the shared
            // default display: Flutter and other players may still use it.
            EGL14.eglReleaseThread();
        }
        return result;
    }

    private static int create(EGLDisplay display, EGLConfig config, int[] attributes) {
        EGL14.eglGetError();
        EGLContext context = EGL14.eglCreateContext(
            display, config, EGL14.EGL_NO_CONTEXT, attributes, 0);
        int error = EGL14.eglGetError();
        if (context != null && !context.equals(EGL14.EGL_NO_CONTEXT)) {
            EGL14.eglDestroyContext(display, context);
            return EGL14.EGL_SUCCESS;
        }
        return error;
    }
}
