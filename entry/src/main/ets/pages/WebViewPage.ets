import { webview } from '@kit.ArkWeb';
import { AppColors } from '../utils/Constants';
import { RouterUtil } from '../utils/RouterUtil';
import { ErrorView } from '../components/StateViews';

@Entry
@Component
struct WebViewPage {
  @State title: string = '';
  @State url: string = '';
  @State hasError: boolean = false;
  private controller: webview.WebviewController = new webview.WebviewController();

  aboutToAppear(): void {
    const params: Record<string, Object> = RouterUtil.getParams();
    this.title = String(params['title'] || '');
    this.url = String(params['url'] || '');
    if (!this.url || this.url.length === 0) {
      this.hasError = true;
    }
  }

  private onBack(): void {
    RouterUtil.back();
  }

  build() {
    Column() {
      this.NavBar();

      if (this.hasError) {
        Column() {
          ErrorView({ message: '页面地址无效', onRetry: () => this.onBack() })
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
      } else {
        Web({ src: this.url, controller: this.controller })
          .width('100%')
          .layoutWeight(1)
          .domStorageAccess(true)
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(AppColors.BG)
  }

  @Builder
  NavBar() {
    Row() {
      Image($r('app.media.examDetail_back'))
        .width(40)
        .height(40)
        .padding(10)
        .backgroundColor(AppColors.CARD)
        .borderRadius(20)
        .onClick(() => this.onBack())

      Text(this.title || '详情')
        .fontSize(17)
        .fontWeight(FontWeight.Bold)
        .fontColor(AppColors.TEXT_PRIMARY)
        .layoutWeight(1)
        .textAlign(TextAlign.Center)
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })

      Row()
        .width(40)
        .height(40)
    }
    .width('100%')
    .height(56)
    .padding({ left: 8, right: 8 })
    .backgroundColor(Color.White)
  }
}
