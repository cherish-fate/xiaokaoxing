import { AppColors, AppSize } from '../utils/Constants';
import { ToastUtil } from '../utils/ToastUtil';
import { RouterUtil } from '../utils/RouterUtil';
import { RouteUrls } from '../utils/RouteUrls';
import { voteRepository } from '../repository/VoteRepository';
import { MySubmissionModel, MySubmissionsModel } from '../model/VoteModel';
import { LoadingView, ErrorView } from '../components/StateViews';

enum PageState {
  LOADING = 'LOADING',
  CONTENT = 'CONTENT',
  ERROR = 'ERROR'
}

@Entry
@Component
struct MySubmissionsPage {
  @State pageState: PageState = PageState.LOADING;
  @State errorMsg: string = '';
  @State list: MySubmissionModel[] = [];
  @State isRefreshing: boolean = false;

  aboutToAppear(): void {
    this.pageState = PageState.LOADING;
    this.loadData();
  }

  private loadData(): void {
    this.loadDataWrapper().then(() => {});
  }

  private async loadDataWrapper(): Promise<void> {
    const res = await voteRepository.loadMySubmissions();
    if (res.code === 401) {
      this.pageState = PageState.ERROR;
      this.errorMsg = res.message || '登录已过期，请重新登录';
      setTimeout(() => RouterUtil.toLogin(), 800);
      return;
    }
    if (!res.success || !res.data) {
      this.pageState = PageState.ERROR;
      this.errorMsg = res.message || '加载失败';
      return;
    }
    this.list = res.data.list;
    this.pageState = PageState.CONTENT;
  }

  private async onRefresh(): Promise<void> {
    if (this.isRefreshing) return;
    this.isRefreshing = true;
    const res = await voteRepository.loadMySubmissions();
    this.isRefreshing = false;
    if (res.code === 401) {
      ToastUtil.show('登录已过期，请重新登录');
      setTimeout(() => RouterUtil.toLogin(), 800);
      return;
    }
    if (res.success && res.data) {
      this.list = res.data.list;
      ToastUtil.show('刷新成功');
    } else {
      ToastUtil.show(res.message || '刷新失败');
    }
  }

  private onRetry(): void {
    this.pageState = PageState.LOADING;
    this.loadData();
  }

  private goToVotePage(): void {
    RouterUtil.push(RouteUrls.COMMUNITY_VOTE);
  }

  @Builder
  Header() {
    Stack({ alignContent: Alignment.Top }) {
      Column() {
        Row({ space: 6 }) {
          Image($r('app.media.community_myvote'))
            .width(20)
          Text('我的投稿')
            .fontSize(20)
            .fontWeight(FontWeight.Bold)
            .fontColor(AppColors.TEXT_PRIMARY)
        }
        .justifyContent(FlexAlign.Center)

        Text('查看我提交的考点及审核状态')
          .fontSize(12)
          .fontColor(AppColors.TEXT_SECONDARY)
          .textAlign(TextAlign.Center)
          .padding({ bottom: 10, top: 2 })
      }
      .width('100%')
      .alignItems(HorizontalAlign.Center)

      Row() {
        Image($r('app.media.examDetail_back'))
          .width(22)
          .height(22)
          .onClick(() => RouterUtil.back())
      }
      .width('100%')
      .padding({ left: AppSize.PADDING_MD, top: 2 })
      .justifyContent(FlexAlign.Start)
    }
    .width('100%')
    .padding({ top: 14 })
    .backgroundColor(Color.White)
  }

  @Builder
  SubmissionItemCard(item: MySubmissionModel) {
    Column({ space: 10 }) {
      Row() {
        Row({ space: 8 }) {
          Text(item.subject)
            .fontSize(11)
            .fontColor(item.tagColor())
            .backgroundColor(item.tagBg())
            .padding({ left: 8, right: 8, top: 3, bottom: 3 })
            .borderRadius(10)

          Text(item.statusChipText())
            .fontSize(11)
            .fontColor(item.statusChipColor())
            .backgroundColor(item.statusChipBg())
            .padding({ left: 8, right: 8, top: 3, bottom: 3 })
            .borderRadius(10)

          Text(item.createdAt)
            .fontSize(11)
            .fontColor(AppColors.TEXT_HINT)
            .layoutWeight(1)
            .textAlign(TextAlign.End)
        }
        .width('100%')
        .alignItems(VerticalAlign.Center)
      }

      Text(item.title)
        .fontSize(15)
        .fontWeight(FontWeight.Medium)
        .fontColor(AppColors.TEXT_PRIMARY)
        .width('100%')
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })

      if (item.description && item.description.length > 0) {
        Text(item.description)
          .fontSize(12)
          .fontColor(AppColors.TEXT_SECONDARY)
          .width('100%')
          .maxLines(2)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
      }
    }
    .width('100%')
    .padding(AppSize.PADDING_LG)
    .backgroundColor(Color.White)
    .borderRadius(AppSize.RADIUS_LG)
  }

  @Builder
  StatsHeader() {
    Row({ space: 12 }) {
      Column({ space: 2 }) {
        Text(`${this.list.length}`)
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor(AppColors.TEXT_PRIMARY)
        Text('总投稿')
          .fontSize(11)
          .fontColor(AppColors.TEXT_HINT)
      }
      .layoutWeight(1)

      Column({ space: 2 }) {
        Text(`${this.list.filter((s: MySubmissionModel) => s.isPending()).length}`)
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor('#FF7E02')
        Text('审核中')
          .fontSize(11)
          .fontColor(AppColors.TEXT_HINT)
      }
      .layoutWeight(1)

      Column({ space: 2 }) {
        Text(`${this.list.filter((s: MySubmissionModel) => s.isApproved()).length}`)
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor(AppColors.SUCCESS)
        Text('已通过')
          .fontSize(11)
          .fontColor(AppColors.TEXT_HINT)
      }
      .layoutWeight(1)

      Column({ space: 2 }) {
        Text(`${this.list.filter((s: MySubmissionModel) => s.isRejected()).length}`)
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor(AppColors.DANGER)
        Text('未通过')
          .fontSize(11)
          .fontColor(AppColors.TEXT_HINT)
      }
      .layoutWeight(1)
    }
    .width('100%')
    .padding({ left: AppSize.PADDING_LG, right: AppSize.PADDING_LG, top: 16, bottom: 16 })
    .backgroundColor(Color.White)
    .borderRadius(AppSize.RADIUS_LG)
  }

  @Builder
  EmptyTip() {
    Column({ space: 12 }) {
      Text('📝')
        .fontSize(40)
      Text('你还没有提交过考点')
        .fontSize(14)
        .fontColor(AppColors.TEXT_SECONDARY)
      Button('去提交新考点')
        .fontSize(14)
        .fontWeight(FontWeight.Medium)
        .height(40)
        .backgroundColor(AppColors.PRIMARY)
        .fontColor(Color.White)
        .borderRadius(20)
        .padding({ left: 20, right: 20 })
        .margin({ top: 8 })
        .onClick(() => this.goToVotePage())
    }
    .width('100%')
    .padding({ top: 60, bottom: 60 })
    .alignItems(HorizontalAlign.Center)
    .backgroundColor(Color.White)
    .borderRadius(AppSize.RADIUS_LG)
  }

  @Builder
  LoadingViewSection() {
    Column() {
      LoadingView({ message: '加载中...' })
    }
    .width('100%')
    .layoutWeight(1)
  }

  @Builder
  ErrorViewSection() {
    Column() {
      ErrorView({
        message: this.errorMsg,
        onRetry: () => this.onRetry()
      })
    }
    .width('100%')
    .layoutWeight(1)
  }

  @Builder
  ContentView() {
    Column({ space: 12 }) {
      this.StatsHeader()

      if (this.list.length === 0) {
        this.EmptyTip()
      } else {
        ForEach(this.list, (item: MySubmissionModel) => {
          this.SubmissionItemCard(item)
        }, (item: MySubmissionModel) => `${item.id}_${item.status}`)
      }

      Column()
        .width('100%')
        .height(20)
    }
    .width('100%')
    .padding({ left: 10, right: 10, top: 12 })
    .backgroundColor(AppColors.BG)
  }

  build() {
    Stack({ alignContent: Alignment.Bottom }) {
      Column() {
        this.Header()

        if (this.pageState === PageState.LOADING) {
          this.LoadingViewSection()
        } else if (this.pageState === PageState.ERROR) {
          this.ErrorViewSection()
        } else {
          Refresh({ refreshing: this.isRefreshing, friction: 100 }) {
            Scroll() {
              this.ContentView()
            }
            .scrollBar(BarState.Off)
            .width('100%')
          }
          .onStateChange((refreshState: RefreshStatus) => {
            if (refreshState === RefreshStatus.Refresh) {
              this.onRefresh();
            }
          })
          .width('100%')
          .layoutWeight(1)
        }
      }
      .width('100%')
      .height('100%')
      .backgroundColor(AppColors.BG)
    }
    .width('100%')
    .height('100%')
  }
}
