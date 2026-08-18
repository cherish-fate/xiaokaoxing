import { AppColors, AppSize } from '../utils/Constants';
import { ToastUtil } from '../utils/ToastUtil';
import { RouterUtil } from '../utils/RouterUtil';
import { RouteUrls } from '../utils/RouteUrls';
import { teamRepository } from '../repository/TeamRepository';
import {
  TeamDetailModel,
  TeamMemberModel,
  ApplicationsModel,
  JoinApplicationModel
} from '../model/TeamModel';

@Entry
@Component
struct TeamDetailPage {
  @State pageState: string = 'LOADING';
  @State teamId: number = 0;
  @State detail: TeamDetailModel = TeamDetailModel.empty();
  @State applications: ApplicationsModel = ApplicationsModel.empty();
  @State showApplications: boolean = false;
  @State tab: number = 0; // 0成员 1信息

  @State confirmTitle: string = '';
  @State confirmMessage: string = '';
  @State showConfirm: boolean = false;
  @State confirmAction: (() => void) | null = null;
  private isFirstShow: boolean = true;

  async aboutToAppear(): Promise<void> {
    this.pageState = 'LOADING';
    // 在 aboutToAppear 中读取路由参数（onPageShow 触发晚于 aboutToAppear，会导致 teamId 为 0）
    const params = RouterUtil.getParams();
    if (params && params['id'] !== undefined) {
      this.teamId = Number(params['id']);
    }
    await this.load();
  }

  onPageShow() {
    if (this.isFirstShow) {
      this.isFirstShow = false;
      return;
    }
    // 从子页面返回时刷新数据
    if (this.teamId) {
      this.load();
    }
  }

  private async load() {
    if (!this.teamId) {
      this.pageState = 'ERROR';
      return;
    }
    const res = await teamRepository.loadTeamDetail(this.teamId);
    if (res.code === 401) { setTimeout(() => RouterUtil.toLogin(), 800); return; }
    if (res.code === 404) { ToastUtil.show(res.message || '小队不存在'); RouterUtil.back(); return; }
    if (res.success && res.data) this.detail = res.data;
    else ToastUtil.show(res.message || '加载失败');

    if (this.detail.isCreator) {
      const ap = await teamRepository.loadApplications(this.teamId);
      if (ap.success && ap.data) this.applications = ap.data;
    }
    this.pageState = 'CONTENT';
  }

  private async join() {
    const res = await teamRepository.joinTeam(this.teamId);
    ToastUtil.show(res.message || (res.success ? '操作成功' : '操作失败'));
    if (res.success) await this.load();
  }

  private async approve(id: number) {
    const res = await teamRepository.approveApplication(this.teamId, id);
    ToastUtil.show(res.message || (res.success ? '已通过' : '操作失败'));
    if (res.success) {
      await this.load();
      if (this.showApplications) {
        const ap = await teamRepository.loadApplications(this.teamId);
        if (ap.success && ap.data) this.applications = ap.data;
      }
    }
  }

  private async reject(id: number) {
    const res = await teamRepository.rejectApplication(this.teamId, id);
    ToastUtil.show(res.message || (res.success ? '已拒绝' : '操作失败'));
    if (res.success) {
      const ap = await teamRepository.loadApplications(this.teamId);
      if (ap.success && ap.data) this.applications = ap.data;
    }
  }

  private promptLeave() {
    this.confirmTitle = '确认退出小队？';
    this.confirmMessage = '退出后将不再记录小队打卡数据';
    this.confirmAction = async () => {
      const res = await teamRepository.leaveTeam(this.teamId);
      ToastUtil.show(res.message || (res.success ? '已退出小队' : '操作失败'));
      this.showConfirm = false;
      if (res.success) RouterUtil.back();
    };
    this.showConfirm = true;
  }

  private promptDisband() {
    this.confirmTitle = '确认解散小队？';
    this.confirmMessage = '解散后所有成员将被移除，且不可恢复';
    this.confirmAction = async () => {
      const res = await teamRepository.disbandTeam(this.teamId);
      ToastUtil.show(res.message || (res.success ? '小队已解散' : '操作失败'));
      this.showConfirm = false;
      if (res.success) {
        setTimeout(() => RouterUtil.back(), 400);
      }
    };
    this.showConfirm = true;
  }

  @Builder
  Header() {
    Row() {
      Image($r('app.media.examDetail_back')).width(22).height(22)
        .onClick(() => RouterUtil.back())
      Text('小队详情')
        .fontSize(18).fontWeight(FontWeight.Medium)
        .fontColor(AppColors.TEXT_PRIMARY)
        .layoutWeight(1).textAlign(TextAlign.Center)
        .margin({ right: 22 })
    }
    .width('100%')
    .padding({ left: AppSize.PADDING_MD, right: AppSize.PADDING_MD, top: 14, bottom: 12 })
    .backgroundColor(Color.White)
  }

  @Builder
  TeamHead() {
    Column({ space: 16 }) {
      Row() {
        Text('📚')
          .fontSize(28)
          .width(56).height(56)
          .backgroundColor('#E8F0FF')
          .borderRadius(16)
          .textAlign(TextAlign.Center)
          .margin({ right: 12 })

        Column({ space: 6 }) {
          Row({ space: 6 }) {
            Text(this.detail.name)
              .fontSize(18).fontWeight(FontWeight.Bold)
              .fontColor(AppColors.TEXT_PRIMARY)
            if (this.detail.isCreator) {
              Text('队长')
                .fontSize(11).fontColor(Color.White)
                .backgroundColor(AppColors.PRIMARY)
                .padding({ left: 8, right: 8, top: 2, bottom: 2 })
                .borderRadius(9)
            } else if (this.detail.isMember) {
              Text('成员')
                .fontSize(11).fontColor(AppColors.PRIMARY)
                .backgroundColor('#E8F0FF')
                .padding({ left: 8, right: 8, top: 2, bottom: 2 })
                .borderRadius(9)
            }
          }
          Text(this.detail.subject)
            .fontSize(12).fontColor(AppColors.TEXT_SECONDARY)
          if (this.detail.description) {
            Text(this.detail.description)
              .fontSize(12).fontColor(AppColors.TEXT_HINT)
              .maxLines(2)
          }
        }
        .layoutWeight(1).alignItems(HorizontalAlign.Start)
      }
      .width('100%')

      Row() {
        this.InfoItem(`${this.detail.memberCount}/${this.detail.maxMembers}`, '成员数')
        this.InfoItem(`${this.detail.checkinRate.toFixed(0)}%`, '打卡率')
        this.InfoItem(`${this.detail.totalCheckins}`, '累计打卡')
        this.InfoItem(this.detail.needApproval ? '需审核' : '自由', '加入')
      }
      .width('100%')
    }
    .width('100%')
    .padding(AppSize.PADDING_LG)
    .backgroundColor(Color.White)
    .borderRadius(AppSize.RADIUS_LG)
  }

  @Builder
  InfoItem(value: string, label: string) {
    Column({ space: 4 }) {
      Text(value).fontSize(15).fontWeight(FontWeight.Medium).fontColor(AppColors.TEXT_PRIMARY)
      Text(label).fontSize(11).fontColor(AppColors.TEXT_HINT)
    }
    .layoutWeight(1)
  }

  @Builder
  ActionBar() {
    Row({ space: 10 }) {
      if (this.detail.isCreator) {
        Button(this.applications.total > 0 ? `申请(${this.applications.total})` : '查看申请')
          .fontSize(14).height(40).layoutWeight(1)
          .backgroundColor('#F0F4FF').fontColor(AppColors.PRIMARY)
          .borderRadius(20)
          .onClick(() => { this.showApplications = true; })

        Button('解散小队')
          .fontSize(14).height(40).layoutWeight(1)
          .backgroundColor('#FFF0F0').fontColor(AppColors.DANGER)
          .borderRadius(20)
          .onClick(() => this.promptDisband())
      } else if (this.detail.isMember) {
        Button('去打卡')
          .fontSize(14).height(40).layoutWeight(1)
          .backgroundColor(AppColors.PRIMARY).fontColor(Color.White)
          .borderRadius(20)
          .onClick(() => RouterUtil.push(RouteUrls.COMMUNITY_CHECKIN))

        Button('退出小队')
          .fontSize(14).height(40).layoutWeight(1)
          .backgroundColor('#F2F5FA').fontColor(AppColors.TEXT_SECONDARY)
          .borderRadius(20)
          .onClick(() => this.promptLeave())
      } else {
        Button('加入小队')
          .fontSize(14).height(40).layoutWeight(1)
          .backgroundColor(AppColors.PRIMARY).fontColor(Color.White)
          .borderRadius(20)
          .onClick(() => this.join())
      }
    }
    .width('100%')
    .padding(AppSize.PADDING_MD)
    .backgroundColor(Color.White)
    .borderRadius(AppSize.RADIUS_LG)
  }

  @Builder
  TabBar() {
    Row() {
      this.TabBtn('成员', 0)
      this.TabBtn('小队信息', 1)
    }
    .width('100%')
    .backgroundColor(Color.White)
    .borderRadius(AppSize.RADIUS_LG)
    .padding(4)
  }

  @Builder
  TabBtn(label: string, index: number) {
    Text(label)
      .fontSize(14)
      .fontWeight(this.tab === index ? FontWeight.Medium : FontWeight.Normal)
      .fontColor(this.tab === index ? AppColors.PRIMARY : AppColors.TEXT_SECONDARY)
      .width('50%').height(38).textAlign(TextAlign.Center)
      .backgroundColor(this.tab === index ? '#E8F0FF' : Color.Transparent)
      .borderRadius(AppSize.RADIUS_MD)
      .onClick(() => { this.tab = index; })
  }

  @Builder
  MemberList() {
    Column({ space: 0 }) {
      ForEach(this.detail.members, (m: TeamMemberModel, idx: number) => {
        Row({ space: 12 }) {
          Circle().width(40).height(40).fill('#F5F0FF')
          Column({ space: 4 }) {
            Row() {
              Text(m.nickname)
                .fontSize(14).fontWeight(FontWeight.Medium).fontColor(AppColors.TEXT_PRIMARY)
                .layoutWeight(1)
              Text(m.role)
                .fontSize(11)
                .fontColor(m.role === '队长' ? Color.White : AppColors.TEXT_SECONDARY)
                .backgroundColor(m.role === '队长' ? AppColors.PRIMARY : '#F2F5FA')
                .padding({ left: 8, right: 8, top: 2, bottom: 2 })
                .borderRadius(9)
            }
            .width('100%')
            Text(`加入时间: ${m.joinedAt}`)
              .fontSize(11).fontColor(AppColors.TEXT_HINT)
          }
          .layoutWeight(1).alignItems(HorizontalAlign.Start)
        }
        .width('100%')
        .padding({ left: AppSize.PADDING_MD, right: AppSize.PADDING_MD, top: 12, bottom: 12 })
        .backgroundColor(Color.White)
        if (idx < this.detail.members.length - 1) {
          Divider().color(AppColors.DIVIDER).margin({ left: 68 })
        }
      })
    }
    .width('100%')
    .borderRadius(AppSize.RADIUS_LG)
    .clip(true)
  }

  @Builder
  InfoPanel() {
    Column({ space: 12 }) {
      this.InfoRow('队长', this.detail.isCreator ? '我' : `用户 #${this.detail.creatorId}`)
      this.InfoRow('科目', this.detail.subject)
      this.InfoRow('成员上限', `${this.detail.maxMembers}人`)
      this.InfoRow('加入方式', this.detail.needApproval ? '需队长审核' : '自由加入')
      this.InfoRow('小队简介', this.detail.description || '暂无简介', true)
    }
    .width('100%')
    .padding(AppSize.PADDING_MD)
    .backgroundColor(Color.White)
    .borderRadius(AppSize.RADIUS_LG)
  }

  @Builder
  InfoRow(label: string, value: string, long: boolean = false) {
    if (long) {
      Column({ space: 6 }) {
        Text(label).fontSize(12).fontColor(AppColors.TEXT_HINT)
        Text(value).fontSize(13).fontColor(AppColors.TEXT_PRIMARY).width('100%')
      }
      .width('100%').alignItems(HorizontalAlign.Start)
    } else {
      Row() {
        Text(label).fontSize(13).fontColor(AppColors.TEXT_HINT).width(80)
        Text(value).fontSize(13).fontColor(AppColors.TEXT_PRIMARY).layoutWeight(1)
      }
      .width('100%')
    }
  }

  @Builder
  ApplicationsSheet() {
    Column() {
      Row() {
        Text('入队申请').fontSize(18).fontWeight(FontWeight.Bold).fontColor(AppColors.TEXT_PRIMARY)
          .layoutWeight(1)
        Text('✕').fontSize(20).fontColor(AppColors.TEXT_HINT)
          .onClick(() => { this.showApplications = false; })
      }
      .width('100%').margin({ bottom: 16 })

      if (this.applications.pending.length === 0) {
        Column({ space: 6 }) {
          Text('📭').fontSize(36)
          Text('暂无待审核申请').fontSize(14).fontColor(AppColors.TEXT_HINT)
        }
        .width('100%').padding({ top: 40, bottom: 40 })
      } else {
        Column({ space: 0 }) {
          ForEach(this.applications.pending, (a: JoinApplicationModel) => {
            Row({ space: 12 }) {
              Circle().width(40).height(40).fill('#F5F0FF')
              Column({ space: 4 }) {
                Text(a.nickname).fontSize(14).fontWeight(FontWeight.Medium).fontColor(AppColors.TEXT_PRIMARY)
                Text(`申请时间: ${a.appliedAt}`).fontSize(11).fontColor(AppColors.TEXT_HINT)
              }
              .layoutWeight(1).alignItems(HorizontalAlign.Start)

              Row({ space: 8 }) {
                Button('拒绝')
                  .fontSize(12).height(28)
                  .backgroundColor('#F2F5FA').fontColor(AppColors.TEXT_SECONDARY)
                  .borderRadius(14).padding({ left: 14, right: 14 })
                  .onClick(() => this.reject(a.applicationId))
                Button('通过')
                  .fontSize(12).height(28)
                  .backgroundColor(AppColors.PRIMARY).fontColor(Color.White)
                  .borderRadius(14).padding({ left: 14, right: 14 })
                  .onClick(() => this.approve(a.applicationId))
              }
            }
            .width('100%')
            .padding({ left: 4, right: 4, top: 12, bottom: 12 })
            Divider().color(AppColors.DIVIDER)
          })
        }
        .width('100%')
      }
    }
    .width('100%')
    .padding(AppSize.PADDING_LG)
    .backgroundColor(Color.White)
    .borderRadius({ topLeft: AppSize.RADIUS_XL, topRight: AppSize.RADIUS_XL })
    .margin({ bottom: 18 })
  }

  @Builder
  ConfirmDialog() {
    Column({ space: 16 }) {
      Text(this.confirmTitle).fontSize(16).fontWeight(FontWeight.Bold).fontColor(AppColors.TEXT_PRIMARY)
      Text(this.confirmMessage).fontSize(13).fontColor(AppColors.TEXT_SECONDARY)
      Row({ space: 10 }) {
        Button('取消')
          .fontSize(14).height(40).layoutWeight(1)
          .backgroundColor('#F2F5FA').fontColor(AppColors.TEXT_SECONDARY)
          .borderRadius(20)
          .onClick(() => { this.showConfirm = false; })
        Button('确定')
          .fontSize(14).height(40).layoutWeight(1)
          .backgroundColor(AppColors.PRIMARY).fontColor(Color.White)
          .borderRadius(20)
          .onClick(() => {
            const act = this.confirmAction;
            if (act) act();
          })
      }
      .width('100%')
    }
    .width(280)
    .padding(AppSize.PADDING_LG)
    .backgroundColor(Color.White)
    .borderRadius(AppSize.RADIUS_LG)
  }

  build() {
    Stack({ alignContent: Alignment.Center }) {
      Column() {
        this.Header()
        if (this.pageState === 'LOADING') {
          Column() { LoadingProgress().color(AppColors.PRIMARY) }
            .layoutWeight(1).width('100%').justifyContent(FlexAlign.Center)
            .backgroundColor(AppColors.BG)
        } else {
          Scroll() {
            Column({ space: 14 }) {
              this.TeamHead()
              this.ActionBar()
              this.TabBar()
              if (this.tab === 0) this.MemberList(); else this.InfoPanel()
            }
            .width('100%')
            .padding(AppSize.PADDING_MD)
          }
          .layoutWeight(1).width('100%').scrollBar(BarState.Off)
          .backgroundColor(AppColors.BG)
        }
      }
      .width('100%').height('100%')

      if (this.showApplications) {
        Column()
          .width('100%').height('100%')
          .backgroundColor('rgba(0,0,0,0.5)')
          .onClick(() => { this.showApplications = false; })
      }
      if (this.showApplications) {
        Column() {
          Scroll() {
            this.ApplicationsSheet()
          }.width('100%').scrollBar(BarState.Off)
        }
        .width('100%')
        .position({ x: 0, y: '30%' })
      }

      if (this.showConfirm) {
        Column()
          .width('100%').height('100%')
          .backgroundColor('rgba(0,0,0,0.5)')
        this.ConfirmDialog()
      }
    }
    .width('100%').height('100%').backgroundColor(AppColors.BG)
  }
}
