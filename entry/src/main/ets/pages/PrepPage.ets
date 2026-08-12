import { router } from '@kit.ArkUI';
import { AppColors, AppSize } from '../utils/Constants';
import { ToastUtil } from '../utils/ToastUtil';
import { Logger } from '../utils/Logger';
import { PrepPageModel, RecommendationItemModel, PrepResourceItemModel } from '../model/PrepModel';
import { prepRepository } from '../repository/PrepRepository';
import { AiAssistantCard } from '../components/AiAssistantCard';
import { QuickFunctionBar } from '../components/QuickFunctionBar';
import { AiRecommendSection } from '../components/AiRecommendSection';
import { PrepResourceSection } from '../components/PrepResourceSection';
import { RouterUtil } from '../utils/RouterUtil';
import { BottomTabBar } from '../components/BottomTabBar';

const TAG = 'PrepPage';
const PAGE_SIZE: number = 10;

@Entry
@Component
struct PrepPage {
  @State pageState: string = 'LOADING';
  @State errorMsg: string = '';
  @State currentCategory: string = '真题试卷';
  @State recommendations: RecommendationItemModel[] = [];
  @State resources: PrepResourceItemModel[] = [];
  @State resourcesTotal: number = 0;
  @State loadMoreState: number = 0;
  @State isRefreshing: boolean = false;

  private offSet: number = 0;
  private categoryChanging: boolean = false;

  async aboutToAppear(): Promise<void> {
    this.pageState = 'LOADING';
    await this.loadData(true);
  }

  private async loadData(reset: boolean = true): Promise<void> {
    if (reset) {
      this.offSet = 0;
      this.categoryChanging = true;
    }
    const res = await prepRepository.loadPrepHome(
      this.currentCategory,
      PAGE_SIZE,
      reset ? 0 : this.offSet
    );
    if (res.code === 401) {
      this.pageState = 'ERROR';
      this.errorMsg = res.message || '登录已过期，请重新登录';
      setTimeout(() => RouterUtil.toLogin(), 800);
      return;
    }
    if (!res.success || !res.data) {
      if (reset) {
        this.pageState = 'ERROR';
        this.errorMsg = res.message || '加载失败';
      } else {
        ToastUtil.show(res.message || '加载失败');
      }
      this.loadMoreState = 2;
      return;
    }
    const data: PrepPageModel = res.data;
    if (reset) {
      this.recommendations = data.recommendations;
      this.resources = data.resources;
    } else {
      this.resources = this.resources.concat(data.resources);
    }
    this.resourcesTotal = data.resourcesTotal;
    this.offSet = this.resources.length;
    this.pageState = 'CONTENT';
    this.loadMoreState = this.resources.length >= this.resourcesTotal ? 2 : 0;
    this.categoryChanging = false;
  }

  private async onCategoryChange(category: string): Promise<void> {
    if (this.categoryChanging || this.currentCategory === category) return;
    this.currentCategory = category;
    this.pageState = 'LOADING';
    await this.loadData(true);
  }

  private async onLoadMore(): Promise<void> {
    if (this.loadMoreState !== 0 || this.pageState !== 'CONTENT') return;
    if (this.resources.length >= this.resourcesTotal) {
      this.loadMoreState = 2;
      return;
    }
    this.loadMoreState = 1;
    await this.loadData(false);
    if (this.loadMoreState === 1) this.loadMoreState = 0;
  }

  private async onRefresh(): Promise<void> {
    if (this.isRefreshing) return;
    this.isRefreshing = true;
    await this.loadData(true);
    this.isRefreshing = false;
  }

  onMoreClick() {
    RouterUtil.pushToResourceList(this.currentCategory);
  }

  onSearchBarTap() {
    RouterUtil.pushToSearch();
  }

  @Builder
  PageHeader() {
    Column({ space: AppSize.PADDING_SM }) {
      Text('备考中心')
        .fontSize(24)
        .fontWeight(FontWeight.Bold)
        .fontColor(AppColors.TEXT_PRIMARY)
        .width('100%')
        .textAlign(TextAlign.Start);

      Row() {
        Image($r('app.media.prep_search'))
          .width(20)
          .margin({ right: AppSize.PADDING_SM });
        Text('搜索科目、资料、真题...')
          .fontSize(14)
          .fontColor(AppColors.TEXT_HINT)
          .layoutWeight(1);
      }
      .width('100%')
      .height(44)
      .padding({ left: AppSize.PADDING_MD, right: AppSize.PADDING_MD })
      .backgroundColor(AppColors.BG)
      .borderRadius(999)
      .border({ width: 1, color: '#0000000A' })
      .onClick(() => this.onSearchBarTap());
    }
    .width('100%')
    .padding({
      left: AppSize.PADDING_LG,
      right: AppSize.PADDING_LG,
      top: AppSize.PADDING_MD,
      bottom: AppSize.PADDING_SM
    })
    .backgroundColor(AppColors.CARD);
  }

  @Builder
  LoadingView() {
    Column() {
      LoadingProgress()
        .width(32)
        .height(32)
        .color(AppColors.PRIMARY)
        .margin({ bottom: AppSize.PADDING_MD });
      Text('正在加载备考中心...')
        .fontSize(14)
        .fontColor(AppColors.TEXT_SECONDARY);
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center);
  }

  @Builder
  ErrorView() {
    Column() {
      Text('⚠️')
        .fontSize(40)
        .margin({ bottom: AppSize.PADDING_MD });
      Text(this.errorMsg || '加载失败，请重试')
        .fontSize(14)
        .fontColor(AppColors.TEXT_SECONDARY)
        .margin({ bottom: AppSize.PADDING_LG });
      Text('点击重试')
        .fontSize(14)
        .fontColor(AppColors.CARD)
        .padding({ left: AppSize.PADDING_LG, right: AppSize.PADDING_LG, top: 10, bottom: 10 })
        .backgroundColor(AppColors.PRIMARY)
        .borderRadius(999)
        .onClick(() => {
          this.pageState = 'LOADING';
          this.loadData(true);
        });
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .padding(AppSize.PADDING_LG);
  }

  @Builder
  ContentView() {
    Column({ space: AppSize.PADDING_MD }) {
      AiAssistantCard();

      QuickFunctionBar();

      AiRecommendSection({ recommendations: $recommendations });

      PrepResourceSection({
        currentCategory: $currentCategory,
        resources: $resources,
        resourcesTotal: $resourcesTotal,
        loadMoreState: $loadMoreState,
        pageState: $pageState,
        onCategoryChange: (cat: string) => this.onCategoryChange(cat),
        onLoadMore: () => this.onLoadMore(),
        onMoreClick: ():void => this.onMoreClick()
      });

      Blank().height(90);
    }
    .width('100%')
    .padding({
      left: AppSize.PADDING_LG,
      right: AppSize.PADDING_LG,
      top: AppSize.PADDING_MD,
      bottom: AppSize.PADDING_MD
    });
  }

  build() {
    Column() {
      this.PageHeader();

      Stack({ alignContent: Alignment.Bottom }) {
        Column() {
          if (this.pageState === 'LOADING') {
            this.LoadingView();
          } else if (this.pageState === 'ERROR') {
            this.ErrorView();
          } else {
            Scroll() {
              Column() {
                this.ContentView();
              }
              .width('100%');
            }
            .width('100%')
            .layoutWeight(1)
            .scrollBar(BarState.Off)
            .onReachEnd(() => this.onLoadMore());
          }
        }
        .width('100%')
        .height('100%')

        BottomTabBar({ currentIndex: 1 });
      }
      .layoutWeight(1)
      .width('100%')
    }
    .width('100%')
    .height('100%')
    .backgroundColor(AppColors.BG);
  }
}
