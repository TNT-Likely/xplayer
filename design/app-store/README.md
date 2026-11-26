# App Store 标题图与搜索结果图

XPlayer 按 iOS 版本归档商店创意素材。每个版本目录保存送审原图、可编辑排版、实际播放器控件和 Apple 预览的核验记录。[2.7.0 海浪主题素材与复现命令](2.7.0/README.md)

## 制作与验收

1. 在 App Store Connect 核对目标 App、平台、已上线版本和商店语言。用对应发布标签的控件取图，并单独记录素材要在当前线上版本生效，还是随下个版本上线。
2. 标题图用于产品页顶部，主体居中。搜索图需要在缩略尺寸下表达播放器的用途。无文字标题图可以跨语言共用，搜索文案和控件标签按商店语言排版。[Apple 素材设计指南](https://developer.apple.com/app-store/asset-best-practices/)
3. 按下表检查裁切。坐标原点在左上角，搜索图的安全区对应表中的最大画布。XPlayer 本次均导出为不透明 sRGB PNG。[Apple 创意素材规格与模板](https://developer.apple.com/help/app-store-connect/reference/app-information/creative-assets-specifications/)

| 展示位 | 本次导出尺寸 | 关键内容安全区 |
| --- | --- | --- |
| 产品页标题 | 3840 × 1646 | 从 (1097, 493) 起，宽 1646、高 661 |
| 搜索结果 | 3840 × 2560 | 从 (836, 765) 起，宽 2168、高 1030 |

4. 在小尺寸预览中检查标题、按钮文字和画面主体。上传后，逐张读回 Apple 识别的文件名、像素尺寸和预览图。保存原文件的 SHA-256，并按同一尺寸比对本地原图与 Apple 预览。[2.7.0 的图片核验记录](2.7.0/verification.json)

## 在 App Store Connect 发布

| 上线时机 | 提交与发布顺序 |
| --- | --- |
| 更新已上线版本 | 在「素材库」上传创意素材，单独加入 iOS 审核。素材获批后，打开当前线上版本的「标题和搜索结果」，选择语言，在各展示位「浏览素材」并点「发布」。 |
| 跟下一版一起上线 | 在下一版草稿选择各语言的标题图与搜索图，再按正常流程送审该版本。Apple 会将已关联的素材纳入同一次审核，随版本发布。 |

素材库显示「已批准」后，仍要核对版本页中每种语言的两个展示位。英语和简体中文共用一张标题图、分别使用一张搜索图时，共有三份文件、四处关联。[已上线版本更换素材](https://developer.apple.com/help/app-store-connect/manage-app-information/manage-your-app-store-assets#manage-creative-assets) · [素材随版本或独立送审](https://developer.apple.com/help/app-store-connect/manage-submissions-to-app-review/submit-assets-from-asset-library/)

使用 App Store Connect API 时可按以下顺序核验。

| 环节 | 资源与回读内容 |
| --- | --- |
| 上传 | 从 App 的 `assetLibrary` 创建 `appAssetLibraryImages`，按返回的 `uploadOperations` 写入，再设置 `uploaded=true`。等 Apple 处理完成，核对 `specId`、尺寸与预览。 |
| 独立审核 | 创建 iOS `reviewSubmissions`，为每张图片添加一个 `reviewSubmissionItems`。提交前核对图片清单，提交后记录 `submittedDate`、提交状态和各素材状态。 |
| 线上发布 | 全部图片获批后，对目标版本的 `appStoreVersionLocalizations` 设置 `DEFAULT_PROFILE` 下的 `PRODUCT_PAGE_HEADER_ASSET` 和 `APP_STORE_SEARCH_RESULTS_ASSET`。按语言回读各展示位的图片 ID 和状态，重试前先检查已存在的关联。 |
