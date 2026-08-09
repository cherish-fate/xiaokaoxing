import { AppColors } from '../utils/Constants';
import { AppText } from '../utils/Constants';
import { RouteUrls } from '../utils/RouteUrls';
import { RouterUtil } from '../utils/RouterUtil';

export enum TabIndex {
  HOME = 0,
  PREP = 1,
  COMMUNITY = 2,
  TOOL = 3,
  ME = 4
}
interface tabsComponent{
  icon:Resource
  label: string
  index: TabIndex
  url: string
}
@Component
export struct BottomTabBar {
  @Prop currentIndex: number = TabIndex.HOME;
  onChange: (index: number) => void = () => {};

  private tabs: Array<tabsComponent> = [
    { icon: $r('app.media.home_home'), label: AppText.TAB_HOME, index: TabIndex.HOME, url: RouteUrls.HOME },
    { icon:$r('app.media.home_beikao'), label: AppText.TAB_PREP, index: TabIndex.PREP, url: RouteUrls.TASK_PREP },
    { icon: $r('app.media.home_community'), label: AppText.TAB_COMMUNITY, index: TabIndex.COMMUNITY, url: '' },
    { icon: $r('app.media.home_tool'), label: AppText.TAB_TOOL, index: TabIndex.TOOL, url: '' },
    { icon: $r('app.media.home_mine'), label: AppText.TAB_ME, index: TabIndex.ME, url: '' }
  ];

  build() {
    Row() {
      ForEach(this.tabs, (item:tabsComponent) => {
        this.TabItem(item)
      })
    }
    .width('100%')
    .height(56)
    .backgroundColor(Color.White)
    .shadow({ radius: 8, color: 'rgba(0,0,0,0.06)', offsetY: -2 })
    .justifyContent(FlexAlign.SpaceAround)
  }

  @Builder
  TabItem(item: tabsComponent) {
    Column({ space: 3 }) {
      Text(item.icon)
        .width(40)
      Text(item.label)
        .fontSize(18)
        .fontColor(this.currentIndex === item.index ? AppColors.PRIMARY : AppColors.TEXT_HINT)
        .fontWeight(this.currentIndex === item.index ? FontWeight.Medium : FontWeight.Normal)
    }
    .layoutWeight(1)
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .onClick(() => {
      if (item.index !== this.currentIndex) {
        this.onChange(item.index);
        if (item.url) {
          RouterUtil.replace(item.url);
        }
      }
    })
  }
}
