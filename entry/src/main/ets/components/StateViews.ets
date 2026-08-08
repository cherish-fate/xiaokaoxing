import { AppColors, AppSize } from '../utils/Constants';

@Component
export struct LoadingView {
  @State message: string = '加载中...';

  build() {
    Column({ space: 12 }) {
      LoadingProgress()
        .width(40)
        .height(40)
        .color(AppColors.PRIMARY)
      Text(this.message)
        .fontSize(14)
        .fontColor(AppColors.TEXT_HINT)
    }
    .width('100%')
    .padding({ top: 40, bottom: 40 })
    .justifyContent(FlexAlign.Center)
  }
}

@Component
export struct EmptyView {
  @State icon: string = '📭';
  @State message: string = '暂无数据';
  @State actionText: string = '';
  onAction: () => void = () => {};

  build() {
    Column({ space: 12 }) {
      Text(this.icon)
        .fontSize(48)
      Text(this.message)
        .fontSize(14)
        .fontColor(AppColors.TEXT_HINT)
      if (this.actionText.length > 0) {
        Button(this.actionText)
          .height(36)
          .padding({ left: 20, right: 20 })
          .backgroundColor(AppColors.PRIMARY)
          .borderRadius(18)
          .fontSize(13)
          .fontColor(Color.White)
          .onClick(() => this.onAction())
      }
    }
    .width('100%')
    .padding({ top: 24, bottom: 24 })
    .justifyContent(FlexAlign.Center)
  }
}

@Component
export struct ErrorView {
  @State message: string = '加载失败';
  onRetry: () => void = () => {};

  build() {
    Column({ space: 12 }) {
      Text('⚠️')
        .fontSize(48)
      Text(this.message)
        .fontSize(14)
        .fontColor(AppColors.TEXT_SECONDARY)
      Button('点击重试')
        .height(36)
        .padding({ left: 20, right: 20 })
        .backgroundColor(AppColors.PRIMARY)
        .borderRadius(18)
        .fontSize(13)
        .fontColor(Color.White)
        .onClick(() => this.onRetry())
    }
    .width('100%')
    .padding({ top: 24, bottom: 24 })
    .justifyContent(FlexAlign.Center)
  }
}
