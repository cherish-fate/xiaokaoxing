import { AppColors } from '../utils/Constants';
import { RouteUrls } from '../utils/RouteUrls';
import { RouterUtil } from '../utils/RouterUtil';

@Component
export struct GreetingBar {
  @Prop greetingText: string = '早安，同学';

  build() {
    Row() {
      Column({ space: 6 }) {
        Row({ space: 8 }) {
          Text(this.greetingText)
            .fontSize(24)
            .fontWeight(FontWeight.Bold)
            .fontColor(AppColors.TEXT_PRIMARY)
        }
      }
      .alignItems(HorizontalAlign.Start)

      Blank()

      Image($r('app.media.home_notice'))
        .width(40)
        .height(40)
        .padding(10)
        .backgroundColor(Color.White)
        .borderRadius(20)
        .fillColor('#ff5a75e8')
        .shadow({ radius: 6, color: 'rgba(0,0,0,0.06)', offsetY: 2 })
        .onClick(() => {
          RouterUtil.push(RouteUrls.NOTIFICATION);
        })
    }
    .width('100%')
    .padding({ left: 20, right: 20, top: 12, bottom: 12 })
  }
}
