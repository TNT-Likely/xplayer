require 'fileutils'

# Bonsoir 5.1.3 calls DNSServiceProcessResult on Flutter's main thread.
# Apply the asynchronous registration used by bonsoir_darwin 7.1.2 to the
# generated Pods project. The upstream release needs Dart 3.13.
def fix_bonsoir_broadcast(installer)
  target = installer.pods_project.targets.find { |t| t.name == 'bonsoir_darwin' }
  return unless target

  entry = target.source_build_phase.files.find { |f| f.file_ref.path.end_with?('BonsoirServiceBroadcast.swift') }
  return unless entry

  source = File.read(entry.file_ref.real_path)
  original = 'DNSServiceProcessResult(sdRef)'
  return unless source.include?(original)

  replacement = <<~SWIFT.strip
    if let reference = sdRef {
                    let queueError = DNSServiceSetDispatchQueue(reference, DispatchQueue.main)
                    if queueError != kDNSServiceErr_NoError {
                        onError(parameters: [service, queueError], details: queueError)
                        dispose()
                    }
                }
  SWIFT
  directory = installer.sandbox.root + 'XPlayerGenerated'
  FileUtils.mkdir_p(directory)
  path = directory + 'BonsoirServiceBroadcast.swift'
  File.write(path, source.sub(original, replacement))
  entry.file_ref = installer.pods_project.main_group.new_file(path)
end
