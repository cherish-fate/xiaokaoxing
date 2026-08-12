import { AppColors, AppSize } from '../utils/Constants';
import { ToastUtil } from '../utils/ToastUtil';
import {
  CommunityHomePageModel,
  CheckinStatsModel,
  HotVoteModel,
  HotTeamModel,
  CommunityResourceModel
} from '../model/CommunityHomeModel';
import { TodayCheckinModel } from '../model/CheckinModel';
import { communityRepository } from '../repository/CommunityRepository';
import { checkinRepository } from '../repository/CheckinRepository';
import { CheckinCard } from '../components/CheckinCard';
import { CommunityQuickBar } from '../components/CommunityQuickBar';
import { HotVoteCard } from '../components/HotVoteCard';
import { HotTeamCard } from '../components/HotTeamCard';
import { CommunityResourceCard } from '../components/CommunityResourceCard';
import { RouterUtil } from '../utils/RouterUtil';
import { BottomTabBar, TabIndex } from '../components/BottomTabBar';

const TAG = 'CommunityPage';

@Entry
@Component
struct CommunityPage {
  @State pageState: string = 'LOADING';
  @State errorMsg: string = '';
  @State isRefreshing: boolean = false;

  @State checkinStats: CheckinStatsModel = CheckinStatsModel.empty();
  @State todayCheckin: TodayCheckinModel = TodayCheckinModel.empty();
  @State hotVotes: HotVoteModel[] = [];
  @State hotTeams: HotTeamModel[] = [];
  @State latestResources: CommunityResourceModel[] = [];

  async aboutToAppear(): Promise<void> {
    this.pageState = 'LOADING';
    await this.loadData();
  }

  private async loadData(): Promise<void> {
    const result= await Promise.all([
      communityRepository.loadCommunityHome(),
      checkinRepository.loadTodayStatus()
    ]);
    const homeRes = result[0];
    const todayRes = result[1];

    if (homeRes.code === 401) {
      this.pageState = 'ERROR';
      this.errorMsg = homeRes.message || '登录已过期，请重新登录';
      setTimeout(() => RouterUtil.toLogin(), 800);
      return;
    }

    // 打卡数据
    if (homeRes.success && homeRes.data) {
      const data: CommunityHomePageModel = homeRes.data;
      this.checkinStats = data.checkinStats;
      this.hotVotes = data.hotVotes;
      this.hotTeams = data.hotTeams;
      this.latestResources = data.latestResources;
    } else if (this.pageState !== 'ERROR') {
      ToastUtil.show(homeRes.message || '社区数据加载失败');
    }

    // 今日打卡状态
    if (todayRes.success && todayRes.data) {
      this.todayCheckin = todayRes.data;
    }

    if (this.pageState === 'ERROR') return;
    this.pageState = 'CONTENT';
  }

  private async onRefresh(): Promise<void> {
    if (this.isRefreshing) return;
    this.isRefreshing = true;
    await this.loadData();
    this.isRefreshing = false;
  }

  @Builder
  LoadingView() {
    Column() {
      LoadingProgress()
        .width(40)
        .height(40)
        .color(AppColors.PRIMARY)
      Text('加载中...')
        .fontSize(14)
        .fontColor(AppColors.TEXT_HINT)
        .margin({ top: 12 })
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .backgroundColor(AppColors.BG)
  }

  @Builder
  ErrorView() {
    Column({ space: 12 }) {
      Text('🙈')
        .fontSize(48)
      Text(this.errorMsg || '加载失败')
        .fontSize(14)
        .fontColor(AppColors.TEXT_HINT)
      Button('重新加载')
        .fontSize(14)
        .height(38)
        .backgroundColor(AppColors.PRIMARY)
        .borderRadius(19)
        .padding({ left: 24, right: 24 })
        .onClick(async () => {
          this.pageState = 'LOADING';
          await this.loadData();
        })
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .backgroundColor(AppColors.BG)
  }

  @Builder
  ContentView() {
    Column({ space: 12 }) {
      CommunityQuickBar()

      CheckinCard({
        checkinStats: $checkinStats,
        todayModel: $todayCheckin
      })

      HotVoteCard({ hotVotes: $hotVotes })

      HotTeamCard({ hotTeams: $hotTeams })

      CommunityResourceCard({ latestResources: $latestResources })
    }
    .width('100%')
    .padding({ left: AppSize.PADDING_MD, right: AppSize.PADDING_MD, top: 12, bottom: 100 })
  }

  build() {
    Column() {
      this.PageHeader()

      Stack({ alignContent: Alignment.Bottom }) {
        Column() {
          if (this.pageState === 'LOADING') {
            this.LoadingView()
          } else if (this.pageState === 'ERROR') {
            this.ErrorView()
          } else {
            Refresh({ refreshing: this.isRefreshing, friction: 100 }) {
              Scroll() {
                this.ContentView()
              }
              .scrollBar(BarState.Off)
              .edgeEffect(EdgeEffect.Spring)
            }
            .onStateChange((refreshState: RefreshStatus) => {
              if (refreshState === RefreshStatus.Refresh) {
                this.onRefresh();
              }
            })
            .layoutWeight(1)
            .width('100%')
          }
        }
        .width('100%')
        .height('100%')

        BottomTabBar({
          currentIndex: TabIndex.COMMUNITY,
          onChange: () => {}
        })
      }
      .layoutWeight(1)
      .width('100%')
    }
    .width('100%')
    .height('100%')
    .backgroundColor(AppColors.BG)
  }

  @Builder
  PageHeader() {
    Row() {
      Text('校园互助圈')
        .fontSize(24)
        .fontWeight(FontWeight.Bold)
        .fontColor(AppColors.TEXT_PRIMARY)
        .layoutWeight(1)
    }
    .width('100%')
    .padding({ left: AppSize.PADDING_MD, right: AppSize.PADDING_MD, top: 16, bottom: 12 })
    .backgroundColor(Color.White)
  }
}
