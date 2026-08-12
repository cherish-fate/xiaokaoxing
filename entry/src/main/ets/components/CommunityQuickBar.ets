import { AppColors, AppSize } from '../utils/Constants';
import { RouterUtil } from '../utils/RouterUtil';
import { RouteUrls } from '../utils/RouteUrls';

interface QuickItem {
  icon: Resource;
  label: string;
  url: string;
  bgColor: string;
}

@Component
export struct CommunityQuickBar {
  private items: QuickItem[] = [
    { icon: $r('app.media.community_checkin'), label: '每日打卡', url: RouteUrls.COMMUNITY_CHECKIN, bgColor: '#ffeaf0fe' },
    { icon: $r('app.media.community_team'), label: '创建小队', url: RouteUrls.COMMUNITY_TEAM, bgColor: '#fffdf7ee' },
    { icon: $r('app.media.community_vote'), label: '考点投票', url: RouteUrls.COMMUNITY_VOTE, bgColor: '#ffeaf6f5' },
    { icon: $r('app.media.community_upload'), label: '上传资料', url: RouteUrls.COMMUNITY_UPLOAD, bgColor: '#fff5f0fe' }
  ];

  build() {
    Row() {
      ForEach(this.items, (item: QuickItem) => {
        Column({ space: 10 }) {
          Column() {
            Image(item.icon)
              .width(24)
          }
          .width(52)
          .height(52)
          .backgroundColor(item.bgColor)
          .borderRadius(16)
          .justifyContent(FlexAlign.Center)
          .alignItems(HorizontalAlign.Center)

          Text(item.label)
            .fontSize(12)
            .fontColor(AppColors.TEXT_PRIMARY)
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Center)
        .onClick(() => RouterUtil.push(item.url))
      })
    }
    .width('100%')
    .padding({ left: AppSize.PADDING_LG, right: AppSize.PADDING_LG, top: 24, bottom: 24 })
    .backgroundColor(Color.White)
    .borderRadius(AppSize.RADIUS_LG)
  }
}
