import { promptAction } from '@kit.ArkUI';
import { AppColors, TagStyle } from '../utils/Constants';
import { ToastUtil } from '../utils/ToastUtil';
import {
  MePageModel,
  MeLearningStatsModel,
  MeContentCountsModel,
  MeCheckinStatsModel
} from '../model/MeModel';
import { meRepository } from '../repository/MeRepository';
import { BottomTabBar, TabIndex } from '../components/BottomTabBar';
import { LoadingView, ErrorView } from '../components/StateViews';
import { RouterUtil } from '../utils/RouterUtil';
import { RouteUrls } from '../utils/RouteUrls';

enum PageState {
  LOADING = 'LOADING',
  CONTENT = 'CONTENT',
  ERROR = 'ERROR'
}

@Entry
@Component
struct MePage {
  @State pageState: PageState = PageState.LOADING;
  @State errorMsg: string = '';
  @State model: MePageModel = MePageModel.empty();
  @State isRefreshing: boolean = false;
  private isFirstShow: boolean = true;

  aboutToAppear(): void {
    this.pageState = PageState.LOADING;
    this.loadDataWrapper();
  }

  onPageShow(): void {
    if (!this.isFirstShow) {
      if (this.pageState === PageState.CONTENT) {
        this.onRefresh();
      } else {
        this.pageState = PageState.LOADING;
        this.loadDataWrapper();
      }
    }
    this.isFirstShow = false;
  }

  private loadDataWrapper(): void {
    this.loadData().then(() => {});
  }

  private async loadData(): Promise<void> {
    const res = await meRepository.loadMePage();
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
    this.model = res.data;
    this.pageState = PageState.CONTENT;
  }

  private async onRefresh(): Promise<void> {
    if (this.isRefreshing) return;
    this.isRefreshing = true;
    const res = await meRepository.loadMePage();
    this.isRefreshing = false;
    if (res.code === 401) {
      this.pageState = PageState.ERROR;
      this.errorMsg = res.message || '登录已过期，请重新登录';
      setTimeout(() => RouterUtil.toLogin(), 800);
      return;
    }
    if (res.success && res.data) {
      this.model = res.data;
      ToastUtil.show('刷新成功');
    } else {
      ToastUtil.show(res.message || '刷新失败');
    }
  }

  private onRetry(): void {
    this.loadData();
  }

  private onEditProfile(): void {
    RouterUtil.pushWithParams(RouteUrls.ME_EDIT, {});
  }

  private goToMyUploads(): void {
    RouterUtil.push(RouteUrls.COMMUNITY_UPLOAD)
  }

  private goToMyVotes(): void {
    RouterUtil.push(RouteUrls.COMMUNITY_VOTE)
  }

  private goToMySubmissions(): void {
    RouterUtil.push(RouteUrls.COMMUNITY_VOTE)
  }

  private goToMyTeams(): void {
    RouterUtil.push(RouteUrls.COMMUNITY_TEAM_DETAIL);
  }

  private goToNotificationSettings(): void {
    RouterUtil.pushWithParams(RouteUrls.NOTIFICATION_SETTINGS, {});
  }

  private goToAbout(): void {
    RouterUtil.pushWithParams(RouteUrls.ABOUT, {});
  }

  private confirmLogout(): void {
    this.doLogout();
  }

  private onLogoutClick(): void {
    this.showConfirm('确定要退出登录吗？').then((ok: boolean) => {
      if (ok) {
        this.confirmLogout();
      }
    });
  }

  private async doLogout(): Promise<void> {
    await meRepository.doLogout();
    ToastUtil.show('已退出登录');
    setTimeout(() => RouterUtil.toLogin(), 300);
  }

  private showConfirm(msg: string): Promise<boolean> {
    return new Promise((resolve: (v: boolean) => void) => {
      promptAction.showDialog({
        message: msg,
        buttons: [
          { text: '取消', color: AppColors.TEXT_SECONDARY },
          { text: '退出', color: AppColors.DANGER }
        ]
      }).then((result: promptAction.ShowDialogSuccessResponse) => {
        resolve(result.index === 1);
      }).catch(() => {
        resolve(false);
      });
    });
  }

  private avatarLetter(): string {
    const name: string = this.model.user.displayName();
    if (name.length === 0) return '同';
    return name.charAt(name.length - 1);
  }

  private metricIcon(index: number): string {
    const icons: string[] = ['📝', '🔖', '📁', '📊', '❓', '🎯'];
    return icons[index] || '📊';
  }

  private metricValueText(index: number): string {
    const learning: MeLearningStatsModel = this.model.learning;
    switch (index) {
      case 0: return `${learning.notesCount}`;
      case 1: return `${learning.bookmarksCount}`;
      case 2: return `${learning.documentsCount}`;
      case 3: return learning.gpaDisplay();
      case 4: return `${learning.dailyQuestionCount}`;
      case 5: return `${learning.examSubjectsCount}`;
      default: return '';
    }
  }

  private metricUnitText(index: number): string {
    switch (index) {
      case 0: return '篇';
      case 1: return '条';
      case 2: return '个';
      case 4: return '题';
      case 5: return '科';
      default: return '';
    }
  }

  private metricLabelText(index: number): string {
    const labels: string[] = ['学习笔记', '精选书签', '个人文档', '当前绩点', '每日一问', '备考科目'];
    return labels[index] || '';
  }

  private contentRowIcon(index: number): string {
    const icons: string[] = ['📤', '🗳️', '📝', '👥'];
    return icons[index] || '📄';
  }

  private contentRowTitle(index: number): string {
    const titles: string[] = ['我的上传', '我的投票', '我的投稿', '我的小队'];
    return titles[index] || '';
  }

  private contentRowSubtitle(index: number): string {
    const subs: string[] = ['已上传资料 · 审核状态', '已投票的考点', '考点投稿记录', '已加入的学习小队'];
    return subs[index] || '';
  }

  private contentRowBadge(index: number): number {
    const counts: MeContentCountsModel = this.model.contentCounts;
    switch (index) {
      case 0: return counts.uploadsCount;
      case 1: return counts.votesCount;
      case 2: return counts.submissionsCount;
      case 3: return counts.teamsCount;
      default: return 0;
    }
  }

  private onContentRowClick(index: number): void {
    switch (index) {
      case 0: this.goToMyUploads(); break;
      case 1: this.goToMyVotes(); break;
      case 2: this.goToMySubmissions(); break;
      case 3: this.goToMyTeams(); break;
      default: break;
    }
  }

  private checkinStatText(i: number): string {
    const stats: MeCheckinStatsModel = this.model.checkin;
    switch (i) {
      case 0: return `${stats.continuousDays}`;
      case 1: return `${stats.totalDays}`;
      case 2: return stats.rankText();
      default: return '';
    }
  }

  private checkinStatLabel(i: number): string {
    switch (i) {
      case 0: return '连续打卡';
      case 1: return '总打卡天';
      case 2: return '打卡排名';
      default: return '';
    }
  }

  @Builder
  ProfileCard() {
    Column() {
      Row({ space: 12 }) {
        if (this.model.user.hasAvatar()) {
          Image(this.model.user.avatarUrl!)
            .width(52)
            .height(52)
            .borderRadius(999)
            .objectFit(ImageFit.Cover)
            .backgroundColor('rgba(255,255,255,0.3)')
        } else {
          Text(this.avatarLetter())
            .fontSize(14)
            .fontWeight(FontWeight.Medium)
            .fontColor('#FFFFFF')
            .width(52)
            .height(52)
            .borderRadius(999)
            .backgroundColor('rgba(255,255,255,0.3)')
            .textAlign(TextAlign.Center)
        }
        Column({ space: 2 }) {
          Text(this.model.user.displayName())
            .fontSize(19)
            .fontWeight(FontWeight.Bold)
            .fontColor('#FFFFFF')
            .lineHeight(24)
          Text(this.model.user.subtitleText())
            .fontSize(13)
            .fontColor('rgba(255,255,255,0.85)')
            .lineHeight(18)
            .margin({ top: 4 })
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)
        Text('✎ 编辑资料')
          .fontSize(12)
          .fontWeight(FontWeight.Medium)
          .fontColor('#FFFFFF')
          .padding({ left: 14, right: 14, top: 7, bottom: 7 })
          .borderRadius(999)
          .backgroundColor('rgba(255,255,255,0.25)')
          .onClick(() => this.onEditProfile())
      }
      .width('100%')

      Row() {
        ForEach([0, 1, 2], (i: number) => {
          Column({ space: 4 }) {
            Text(this.checkinStatText(i))
              .fontSize(20)
              .fontWeight(FontWeight.Bold)
              .fontColor('#FFFFFF')
            Text(this.checkinStatLabel(i))
              .fontSize(12)
              .fontColor('rgba(255,255,255,0.85)')
          }
          .layoutWeight(1)
        })
      }
      .width('100%')
      .margin({ top: 16 })
      .padding({ top: 16 })
      .border({ width: { top: 1 }, color: 'rgba(255,255,255,0.2)' })
    }
    .width('100%')
    .padding(18)
    .borderRadius(18)
    .linearGradient({
      direction: GradientDirection.RightBottom,
      colors: [['#5B8BFF', 0.0], ['#4A7FFF', 1.0]]
    })
    .shadow({ radius: 12, color: 'rgba(74,127,255,0.25)', offsetY: 6 })
  }

  @Builder
  SectionLabel(text: string) {
    Text(text)
      .fontSize(13)
      .fontWeight(FontWeight.Medium)
      .fontColor(AppColors.TEXT_SECONDARY)
      .width('100%')
      .padding({ left: 4, right: 4, bottom: 8, top: 4 })
  }

  @Builder
  MetricCell(index: number) {
    Column({ space: 4 }) {
      Text(this.metricIcon(index))
        .fontSize(20)
        .margin({ bottom: 4 })
      Row() {
        Text(this.metricValueText(index))
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor(AppColors.PRIMARY)
        Text(this.metricUnitText(index))
          .fontSize(12)
          .fontWeight(FontWeight.Medium)
          .fontColor(AppColors.TEXT_HINT)
          .margin({ left: 2 })
      }
      Text(this.metricLabelText(index))
        .fontSize(11)
        .fontColor(AppColors.TEXT_HINT)
        .margin({ top: 4 })
    }
    .width('100%')
    .height(100)
    .padding({ top: 16, bottom: 16, left: 12, right: 12 })
    .backgroundColor(AppColors.CARD)
    .border({ width: 1, color: AppColors.DIVIDER })
    .borderRadius(18)
    .shadow({ radius: 12, color: 'rgba(0,0,0,0.04)' })
  }

  @Builder
  LearningDashboard() {
    Grid() {
      ForEach([0, 1, 2, 3, 4, 5], (idx: number) => {
        GridItem() {
          this.MetricCell(idx)
        }
      })
    }
    .columnsTemplate('1fr 1fr 1fr')
    .rowsTemplate('1fr 1fr')
    .columnsGap(12)
    .rowsGap(12)
    .width('100%')
    .height(212)
    //.aspectRatio(2)
  }

  @Builder
  IconBadge(icon: string) {
    Text(icon)
      .fontSize(16)
      .width(36)
      .height(36)
      .borderRadius(12)
      .backgroundColor(TagStyle.BLUE)
      .textAlign(TextAlign.Center)
  }

  @Builder
  ContentRow(index: number) {
    Row({ space: 12 }) {
      this.IconBadge(this.contentRowIcon(index))
      Column({ space: 2 }) {
        Text(this.contentRowTitle(index))
          .fontSize(15)
          .fontWeight(FontWeight.Medium)
          .fontColor(AppColors.TEXT_PRIMARY)
        Text(this.contentRowSubtitle(index))
          .fontSize(12)
          .fontColor(AppColors.TEXT_HINT)
          .margin({ top: 2 })
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)
      if (index === 0 && this.contentRowBadge(index) > 0) {
        Text(`${this.contentRowBadge(index)}`)
          .fontSize(10)
          .fontWeight(FontWeight.Medium)
          .fontColor('#FFFFFF')
          .padding({ left: 8, right: 8, top: 3, bottom: 3 })
          .borderRadius(999)
          .backgroundColor(AppColors.DANGER)
          .width(18)
          .textAlign(TextAlign.Center)
      }
      Text('›')
        .fontSize(18)
        .fontColor(AppColors.TEXT_HINT)
    }
    .width('100%')
    .padding(16)
    .onClick(() => this.onContentRowClick(index))
  }

  @Builder
  SettingsRow(title: string, subtitle: string, icon: string, onClick: () => void) {
    Row({ space: 12 }) {
      this.IconBadge(icon)
      Column({ space: 2 }) {
        Text(title)
          .fontSize(15)
          .fontWeight(FontWeight.Medium)
          .fontColor(AppColors.TEXT_PRIMARY)
        Text(subtitle)
          .fontSize(12)
          .fontColor(AppColors.TEXT_HINT)
          .margin({ top: 2 })
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)
      Text('›')
        .fontSize(18)
        .fontColor(AppColors.TEXT_HINT)
    }
    .width('100%')
    .padding(16)
    .onClick(onClick)
  }

  @Builder
  LogoutRow() {
    Text('退出登录')
      .fontSize(15)
      .fontWeight(FontWeight.Medium)
      .fontColor(AppColors.DANGER)
      .width('100%')
      .textAlign(TextAlign.Center)
      .padding(16)
      .onClick(() => this.onLogoutClick())
  }

  @Builder
  ContentRowWithDivider(index: number) {
    Column() {
      if (index > 0) {
        Divider()
          .color(AppColors.DIVIDER)
          .strokeWidth(1)
      }
      this.ContentRow(index)
    }
    .width('100%')
  }

  @Builder
  SettingsDividerRow(title: string, subtitle: string, icon: string, showDivider: boolean, onClick: () => void) {
    Column() {
      if (showDivider) {
        Divider()
          .color(AppColors.DIVIDER)
          .strokeWidth(1)
      }
      this.SettingsRow(title, subtitle, icon, onClick)
    }
    .width('100%')
  }

  @Builder
  ContentView() {
    Column({ space: 16 }) {
      this.ProfileCard()

      Column({ space: 0 }) {
        this.SectionLabel('学习数据概览')
        this.LearningDashboard()
      }
      .width('100%')

      Column({ space: 0 }) {
        this.SectionLabel('我的内容')
        Column() {
          ForEach([0, 1, 2, 3], (idx: number) => {
            this.ContentRowWithDivider(idx)
          }, (idx: number) => `my_content_${idx}`)
        }
        .width('100%')
        .backgroundColor(AppColors.CARD)
        .borderRadius(18)
        .border({ width: 1, color: AppColors.DIVIDER })
        .shadow({ radius: 12, color: 'rgba(0,0,0,0.04)' })
      }
      .width('100%')

      Column({ space: 0 }) {
        this.SectionLabel('设置')
        Column() {
          this.SettingsRow('通知设置', this.model.notificationSettings.descriptionText(),
            '🔔', () => this.goToNotificationSettings())
          this.SettingsDividerRow('关于校考星', this.model.about.versionDisplay(),
            'ℹ️', true, () => this.goToAbout())
          Column() {
            Divider()
              .color(AppColors.DIVIDER)
              .strokeWidth(1)
            this.LogoutRow()
          }
          .width('100%')
        }
        .width('100%')
        .backgroundColor(AppColors.CARD)
        .borderRadius(18)
        .border({ width: 1, color: AppColors.DIVIDER })
        .shadow({ radius: 12, color: 'rgba(0,0,0,0.04)' })
      }
      .width('100%')
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 12, bottom: 88 })
  }

  build() {
    Stack({ alignContent: Alignment.Bottom }) {
      Column() {
        if (this.pageState === PageState.LOADING) {
          Column() {
            LoadingView({ message: '加载中...' })
          }
          .width('100%')
          .layoutWeight(1)
        } else if (this.pageState === PageState.ERROR) {
          Column() {
            ErrorView({
              message: this.errorMsg,
              onRetry: () => this.onRetry()
            })
          }
          .width('100%')
          .layoutWeight(1)
        } else {
          Column() {
            this.ContentArea()
          }
          .width('100%')
          .layoutWeight(1)
        }
      }
      .width('100%')
      .height('100%')
      .backgroundColor(AppColors.BG)
      //.expandSafeArea([SafeAreaType.SYSTEM])

      BottomTabBar({
        currentIndex: TabIndex.ME,
        onChange: (_idx: number) => {}
      })
    }
    .width('100%')
    .height('100%')
  }

  @Builder
  ContentArea() {
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
