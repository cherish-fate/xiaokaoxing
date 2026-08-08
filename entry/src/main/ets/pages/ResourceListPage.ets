import { router } from '@kit.ArkUI';
import { resourceRepository } from '../repository/ResourceRepository';
import { ResourceModel } from '../model/ResourceModel';
import { AppColors, AppSize } from '../utils/Constants';
import { RouteUrls } from '../utils/RouteUrls';
import { RouterUtil } from '../utils/RouterUtil';
import { ToastUtil } from '../utils/ToastUtil';
import { Logger } from '../utils/Logger';

const TAG = 'ResourceListPage';

enum PageState {
  LOADING = 'loading',
  CONTENT = 'content',
  ERROR = 'error'
}

@Entry
@Component
struct ResourceListPage {
  @State pageState: PageState = PageState.LOADING;
  @State resourceList: ResourceModel[] = [];
  @State errorMessage: string = '';
  @State isRefreshing: boolean = false;
  @State isLoadingMore: boolean = false;
  @State hasMore: boolean = true;
  @State emptyHint: string = '暂无推荐资源';
  private readonly PAGE_SIZE: number = 10;
  private currentLimit: number = 10;

  aboutToAppear(): void {
    this.loadInitialData();
  }

  private async loadInitialData(): Promise<void> {
    this.pageState = PageState.LOADING;
    this.currentLimit = this.PAGE_SIZE;
    await this.fetchData(false);
  }

  private async fetchData(isLoadMore: boolean): Promise<void> {
    try {
      const result = await resourceRepository.fetchRecommendedResources(this.currentLimit);
      if (result.success && result.data) {
        this.resourceList = result.data;
        this.hasMore = this.resourceList.length >= this.currentLimit;
        this.pageState = PageState.CONTENT;
      } else if (result.code === 401) {
        ToastUtil.show('登录已过期，请重新登录');
        this.pageState = PageState.ERROR;
        this.errorMessage = '登录已过期';
      } else {
        this.pageState = PageState.ERROR;
        this.errorMessage = result.message || '加载失败';
      }
    } catch (e) {
      Logger.error(TAG, 'fetchData failed', e as Error);
      this.pageState = PageState.ERROR;
      this.errorMessage = '网络异常，请检查网络连接';
    }
  }

  private async onRefresh(): Promise<void> {
    if (this.isRefreshing) {
      return;
    }
    this.isRefreshing = true;
    this.currentLimit = this.PAGE_SIZE;
    await this.fetchData(false);
    this.isRefreshing = false;
  }

  private async onLoadMore(): Promise<void> {
    if (this.isLoadingMore || !this.hasMore) {
      return;
    }
    this.isLoadingMore = true;
    const prevCount = this.resourceList.length;
    this.currentLimit += this.PAGE_SIZE;
    await this.fetchData(true);
    if (this.resourceList.length === prevCount) {
      this.hasMore = false;
    }
    this.isLoadingMore = false;
  }

  private handleClose(): void {
    try {
      router.back();
    } catch (e) {
      Logger.error(TAG, 'handleClose failed', e as Error);
    }
  }

  build() {
    Column() {
      this.TopBar();

      if (this.pageState === PageState.LOADING) {
        Column() {
          LoadingProgress()
            .width(40)
            .height(40)
            .color(AppColors.PRIMARY)
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
      } else if (this.pageState === PageState.ERROR) {
        Column() {
          Text('⚠️')
            .fontSize(48)
          Text(this.errorMessage)
            .fontSize(14)
            .fontColor(AppColors.TEXT_SECONDARY)
            .margin({ top: 8 })
          Button('点击重试')
            .height(36)
            .padding({ left: 20, right: 20 })
            .backgroundColor(AppColors.PRIMARY)
            .borderRadius(18)
            .fontSize(13)
            .fontColor(Color.White)
            .margin({ top: 12 })
            .onClick(() => this.loadInitialData())
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
      } else {
        this.ContentArea()
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(AppColors.BG)
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
  }

  @Builder
  TopBar() {
    Row() {
      Image($r('app.media.examDetail_back'))
        .width(40)
        .height(40)
        .padding(10)
        .backgroundColor(AppColors.CARD)
        .borderRadius(20)
        .onClick(() => this.handleClose())
      Blank()

      Text('本校速推资源')
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor(AppColors.TEXT_PRIMARY)
      Blank()
    }
    .width('100%')
    .height(44)
    .padding({ left: 20, right: 20, top: 12, bottom: 12 })
    .alignItems(VerticalAlign.Center)
  }

  @Builder
  ContentArea() {
    Refresh({ refreshing: this.isRefreshing, friction: 100 }) {
      if (this.resourceList.length === 0) {
        Column() {
          Text('📭')
            .fontSize(48)
          Text(this.emptyHint)
            .fontSize(14)
            .fontColor(AppColors.TEXT_HINT)
            .margin({ top: 8 })
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
      } else {
        List({ space: 10 }) {
          ForEach(this.resourceList, (item: ResourceModel) => {
            ListItem() {
              this.ResourceCard(item)
            }
          }, (item: ResourceModel) => `${item.id}`)

          ListItem() {
            this.FooterItem()
          }
        }
        .width('100%')
        .layoutWeight(1)
        .scrollBar(BarState.Off)
        .edgeEffect(EdgeEffect.Spring)
        .onReachEnd(() => this.onLoadMore())
      }
    }
    .onStateChange((refreshState: RefreshStatus) => {
      if (refreshState === RefreshStatus.Refresh) {
        this.onRefresh();
      }
    })
    .width('100%')
    .height('100%')
  }

  @Builder
  ResourceCard(item: ResourceModel) {
    Row({ space: 12 }) {
      // 左侧图标块
      Column() {
        Image($r('app.media.home_material'))
          .width(24)
          .height(24)
          .fillColor(item.tagTextColor())
      }
      .width(48)
      .height(48)
      .borderRadius(AppSize.RADIUS_MD)
      .backgroundColor(item.tagColor())
      .justifyContent(FlexAlign.Center)

      // 右侧内容
      Column({ space: 6 }) {
        Row() {
          Text(item.typeTag)
            .fontSize(11)
            .fontColor(item.tagTextColor())
            .padding({
              left: 8,
              right: 8,
              top: 3,
              bottom: 3
            })
            .backgroundColor(item.tagColor())
            .borderRadius(8)
        }

        Text(item.title)
          .fontSize(15)
          .fontWeight(FontWeight.Medium)
          .fontColor(AppColors.TEXT_PRIMARY)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .width('100%')

        Text(item.description)
          .fontSize(13)
          .fontColor(AppColors.TEXT_SECONDARY)
          .maxLines(2)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .width('100%')
          .lineHeight(20)

        Row({ space: 4 }) {
          Image($r('app.media.home_look'))
            .width(16)
            .fillColor('#ffd3d3d3')
          Text('点击查看')
            .fontSize(12)
            .fontColor(AppColors.TEXT_HINT)
          Blank()
          Text('›')
            .fontSize(14)
            .fontColor(AppColors.TEXT_HINT)
        }
        .width('100%')
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)
    }
    .width('100%')
    .padding(16)
    .backgroundColor(AppColors.CARD)
    .borderRadius(AppSize.RADIUS_LG)
    .shadow({ radius: 4, color: 'rgba(0,0,0,0.04)', offsetY: 2 })
    .onClick(() => {
      RouterUtil.pushWithParams(RouteUrls.RESOURCE_DETAIL, { "resource": item });
    })
  }

  @Builder
  FooterItem() {
    if (this.isLoadingMore) {
      Row({ space: 8 }) {
        LoadingProgress()
          .width(20)
          .height(20)
          .color(AppColors.TEXT_HINT)
        Text('加载中...')
          .fontSize(13)
          .fontColor(AppColors.TEXT_HINT)
      }
      .width('100%')
      .padding({ top: 12, bottom: 12 })
      .justifyContent(FlexAlign.Center)
    } else if (!this.hasMore) {
      Text('— 已加载全部 —')
        .fontSize(12)
        .fontColor(AppColors.TEXT_HINT)
        .width('100%')
        .textAlign(TextAlign.Center)
        .padding({ top: 12, bottom: 12 })
    }
  }
}
