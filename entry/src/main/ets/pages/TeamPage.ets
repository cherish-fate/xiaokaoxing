import { AppColors, AppSize, TagStyle } from '../utils/Constants';
import { ToastUtil } from '../utils/ToastUtil';
import { RouterUtil } from '../utils/RouterUtil';
import { RouteUrls } from '../utils/RouteUrls';
import { teamRepository } from '../repository/TeamRepository';
import {
  TeamListModel, TeamItemModel, CreateTeamArgs
} from '../model/TeamModel';

const SUBJECT_LIST: string[] = ['全部', '高等数学', '大学英语', '线性代数', '数据结构', '大学物理', '计算机组成原理'];

const SUBJECT_COLORS: Record<string, string> = {
  '高等数学': '#E8F0FF',
  '大学英语': '#E6F7F5',
  '线性代数': '#F5F0FF',
  '数据结构': '#FFF3E8',
  '大学物理': '#E6F7F5',
  '计算机组成原理': '#FFF0F0'
};

const SUBJECT_ICONS: Record<string, string> = {
  '高等数学': '📐',
  '大学英语': '📚',
  '线性代数': '📊',
  '数据结构': '💻',
  '大学物理': '⚛️',
  '计算机组成原理': '🖥️'
};

@Entry
@Component
struct TeamPage {
  @State pageState: string = 'LOADING';
  @State data: TeamListModel = TeamListModel.empty();
  @State selSubject: string = '全部';
  @State showCreate: boolean = false;
  @State creating: boolean = false;
  @State createName: string = '';
  @State createSubject: string = '';
  @State createDesc: string = '';
  @State createNeedApproval: boolean = true;
  @State isRefreshing: boolean = false;
  @State isRecommendLoading: boolean = false;

  async aboutToAppear(): Promise<void> {
    this.pageState = 'LOADING';
    await this.load();
  }

  private async load() {
    const res = await teamRepository.loadTeams(this.selSubject === '全部' ? undefined : this.selSubject);
    if (res.code === 401) {
      this.pageState = 'ERROR';
      setTimeout(() => RouterUtil.toLogin(), 800);
      return;
    }
    if (res.success && res.data) {
      this.data = res.data;
    } else {
      ToastUtil.show(res.message || '加载失败');
    }
    this.pageState = 'CONTENT';
  }

  private async onRefresh(): Promise<void> {
    if (this.isRefreshing) return;
    this.isRefreshing = true;
    await this.load();
    this.isRefreshing = false;
  }

  private async loadRecommendedOnly(): Promise<void> {
    this.isRecommendLoading = true;
    const res = await teamRepository.loadTeams(this.selSubject === '全部' ? undefined : this.selSubject);
    if (res.code === 401) {
      this.isRecommendLoading = false;
      ToastUtil.show('登录已过期，请重新登录');
      setTimeout(() => RouterUtil.toLogin(), 800);
      return;
    }
    if (res.success && res.data) {
      this.data = new TeamListModel(this.data.myTeams, res.data.recommendedTeams);
    } else {
      ToastUtil.show(res.message || '加载失败');
    }
    this.isRecommendLoading = false;
  }

  private async doCreate() {
    if (this.creating) {
      return;
    }
    if (!this.createSubject) {
      ToastUtil.show('请选择科目');
      return;
    }
    this.creating = true;
    const args: CreateTeamArgs = {
      name: this.createName,
      subject: this.createSubject,
      description: this.createDesc || undefined,
      needApproval: this.createNeedApproval
    };
    const res = await teamRepository.createTeam(args);
    this.creating = false;
    if (!res.success || !res.data) {
      ToastUtil.show(res.message || '创建失败');
      return;
    }
    ToastUtil.show(res.message || '创建成功');
    this.showCreate = false;
    this.createName = '';
    this.createSubject = '';
    this.createDesc = '';
    this.createNeedApproval = true;
    await this.load();
    RouterUtil.pushWithParams(RouteUrls.COMMUNITY_TEAM_DETAIL, { "id": String(res.data.id) });
  }

  private async joinTeam(t: TeamItemModel) {
    if (t.isMember) {
      RouterUtil.pushWithParams(RouteUrls.COMMUNITY_TEAM_DETAIL, { "id": String(t.id) });
      return;
    }
    const res = await teamRepository.joinTeam(t.id);
    if (res.success) {
      await this.load();
    }
  }

  private getSubjectIcon(subject: string): string {
    return SUBJECT_ICONS[subject] || '🎓';
  }

  private getSubjectColor(subject: string): string {
    return SUBJECT_COLORS[subject] || TagStyle.BLUE;
  }

  @Builder
  Header() {
    Stack({ alignContent: Alignment.Top }) {
      Column() {
        Row({ space: 6 }) {
          Image($r('app.media.community_team'))
            .width(20)
          Text('备考小队')
            .fontSize(20)
            .fontWeight(FontWeight.Bold)
            .fontColor(AppColors.TEXT_PRIMARY)
        }
        .justifyContent(FlexAlign.Center)

        Text('找到同专业小伙伴，一起打卡上岸')
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
  SubjectFilter() {
    Scroll() {
      Row({ space: 10 }) {
        ForEach(SUBJECT_LIST, (s: string) => {
          Row({ space: 6 }) {
            Text(s)
              .fontSize(13)
              .fontWeight(this.selSubject === s ? FontWeight.Medium : FontWeight.Normal)
              .fontColor(this.selSubject === s ? Color.White : AppColors.TEXT_PRIMARY)
          }
          .padding({
            left: 14,
            right: 14,
            top: 8,
            bottom: 8
          })
          .backgroundColor(this.selSubject === s ? AppColors.PRIMARY : '#F2F5FA')

          .borderRadius(18)
          .onClick(async () => {
            if (this.selSubject === s) {
              return;
            }
            this.selSubject = s;
            this.pageState = 'LOADING';
            await this.load();
          })
        })
      }
      .padding({
        left: AppSize.PADDING_MD,
        right: AppSize.PADDING_MD,
        top: 10,
        bottom: 10
      })
    }
    .width('100%')
    .backgroundColor(Color.White)
    .scrollable(ScrollDirection.Horizontal)
    .scrollBar(BarState.Off)
    .edgeEffect(EdgeEffect.Spring)
  }

  @Builder
  MyTeamSection() {
    Column({ space: 10 }) {
      Row() {
        Row({ space: 6 }) {
          Image($r('app.media.community_myteam'))
            .width(20)
          Text('我的小队')
            .fontSize(17)
            .fontWeight(FontWeight.Bold)
            .fontColor(AppColors.TEXT_PRIMARY)
        }
        .layoutWeight(1)

        Text('管理')
          .fontSize(14)
          .fontColor(AppColors.PRIMARY)
          .onClick(() => {
            if (this.data.myTeams.length > 0) {
              RouterUtil.pushWithParams(RouteUrls.COMMUNITY_TEAM_DETAIL, { "id": String(this.data.myTeams[0].id) });
            }
          })
      }
      .width('100%')


      if (this.data.myTeams.length === 0) {
        this.EmptyMyTeams()

      } else {
        ForEach(this.data.myTeams, (t: TeamItemModel) => {
          this.MyTeamCard(t)

        })
      }
    }
    .width('100%')
    .padding({
      left: AppSize.PADDING_MD,
      right: AppSize.PADDING_MD,
      top: 16,
      bottom: 14
    })
    .backgroundColor(Color.White)
    .borderRadius(AppSize.RADIUS_LG)
  }

  @Builder
  MyTeamCard(t: TeamItemModel) {
    Column({ space: 14 }) {
      Row({ space: 12 }) {
        Column() {
          Text(this.getSubjectIcon(t.subject))
            .fontSize(24)
        }
        .width(52)
        .height(52)
        .backgroundColor(this.getSubjectColor(t.subject))
        .borderRadius(14)
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)

        Column({ space: 6 }) {
          Row({ space: 8 }) {
            Text(t.name)
              .fontSize(16)
              .fontWeight(FontWeight.Medium)
              .fontColor(AppColors.TEXT_PRIMARY)
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })

            if (t.isCreator) {
              Row({ space: 3 }) {
                Text('👑')
                  .fontSize(11)
                Text('我创建')
                  .fontSize(11)
                  .fontColor(AppColors.WARNING)
              }
              .padding(5)
              .borderRadius(5)
              .backgroundColor('#ffffefe0')
            }
          }
          .width('100%')

          Row({ space: 8 }) {
            Text(t.subject)
              .fontSize(12)
              .fontColor(AppColors.PRIMARY)
              .backgroundColor('#E8F0FF')
              .padding({ left: 10, right: 10, top: 3, bottom: 3 })
              .borderRadius(10)

            Row({ space: 4 }) {
              Circle()
                .width(6)
                .height(6)
                .fill(AppColors.SUCCESS)
              Text(`${t.onlineCount}人在线 · ${t.memberCount}/${t.maxMembers}人`)
                .fontSize(12)
                .fontColor(AppColors.SUCCESS)
            }
            .padding(5)
            .borderRadius(5)
            .backgroundColor('#ffeaf6f5')
          }
          .width('100%')
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)
      }
      .width('100%')

      Row({ space: 0 }) {
        Column({ space: 2 }) {
          Text(`${t.checkinRate.toFixed(0)}%`)
            .fontSize(20)
            .fontWeight(FontWeight.Bold)
            .fontColor('#4A7FFF')
          Text('打卡率')
            .fontSize(12)
            .fontColor(AppColors.TEXT_SECONDARY)
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Center)

        Column({ space: 2 }) {
          Text(`${t.totalCheckins}`)
            .fontSize(20)
            .fontWeight(FontWeight.Bold)
            .fontColor('#FF9F43')
          Text('总打卡')
            .fontSize(12)
            .fontColor(AppColors.TEXT_SECONDARY)
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Center)

        Column({ space: 2 }) {
          Text(`${t.resourceCount}`)
            .fontSize(20)
            .fontWeight(FontWeight.Bold)
            .fontColor('#A855F7')
          Text('资料数')
            .fontSize(12)
            .fontColor(AppColors.TEXT_SECONDARY)
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Center)
      }
      .width('100%')

      Row() {
        Text('查看小队')
          .fontSize(15)
          .fontWeight(FontWeight.Medium)
          .fontColor(Color.White)
          .width(140)
          .height(42)
          .backgroundColor(AppColors.PRIMARY)
          .borderRadius(16)
          .textAlign(TextAlign.Center)
          .onClick(() => RouterUtil.pushWithParams(RouteUrls.COMMUNITY_TEAM_DETAIL, { "id": String(t.id) }))

        if (t.pendingRequests > 0) {
          Text(`${t.pendingRequests}人待审核`)
            .fontSize(15)
            .width(140)
            .height(42)
            .fontColor(AppColors.TEXT_SECONDARY)
            .textAlign(TextAlign.Center)
        } else {
          Text('0人待审核')
            .fontSize(15)
            .width(140)
            .height(42)
            .fontColor(AppColors.TEXT_SECONDARY)
            .textAlign(TextAlign.Center)
        }
      }
      .justifyContent(FlexAlign.SpaceBetween)
      .width('100%')
    }
    .width('100%')
    .padding(AppSize.PADDING_MD)
    .backgroundColor('#F8FAFC')
    .borderRadius(16)
  }

  @Builder
  CreateTeamButton() {
    Row({ space: 6 }) {
      Text('+')
        .fontSize(18)
        .fontColor(AppColors.PRIMARY)
      Text('创建我的备考小队')
        .fontSize(15)
        .fontWeight(FontWeight.Medium)
        .fontColor(AppColors.PRIMARY)
    }
    .width('100%')
    .margin({ left: AppSize.PADDING_MD, right: AppSize.PADDING_MD })
    .height(56)
    .justifyContent(FlexAlign.Center)
    .border({
      width: 2,
      color: AppColors.PRIMARY,
      radius: 16
    })
    .borderStyle(BorderStyle.Dashed)
    .backgroundColor('#EEF4FF')
    .onClick(() => {
      this.showCreate = true;
    })
  }

  @Builder
  RecommendSection() {
    Column({ space: 10 }) {
      Row() {
        Row({ space: 6 }) {
          Text('🌟')
            .fontSize(18)
          Text('为你推荐')
            .fontSize(17)
            .fontWeight(FontWeight.Bold)
            .fontColor(AppColors.TEXT_PRIMARY)
        }
        .layoutWeight(1)

        Row({ space: 4 }) {
          LoadingProgress()
            .width(14)
            .height(14)
            .color(AppColors.PRIMARY)
            .visibility(this.isRecommendLoading ? Visibility.Visible : Visibility.None)
          Text('换一批')
            .fontSize(14)
            .fontColor(this.isRecommendLoading ? AppColors.TEXT_HINT : AppColors.PRIMARY)
            .onClick(async () => {
              if (!this.isRecommendLoading) {
                await this.loadRecommendedOnly();
              }
            })
        }
      }
      .width('100%')

      if (this.isRecommendLoading) {
        Column({ space: 12 }) {
          ForEach([1, 2], (_: number) => {
            this.RecommendSkeletonCard()
          }, (i: number) => `rec-skeleton-${i}`);
        }
        .width('100%');
      } else if (this.data.recommendedTeams.length === 0) {
        this.EmptyRecommended()
      } else {
        Column({ space: 12 }) {
          ForEach(this.data.recommendedTeams, (t: TeamItemModel) => {
            this.RecommendTeamCard(t)
          })
        }
      }
    }
    .width('100%')
    .padding({
      left: AppSize.PADDING_MD,
      right: AppSize.PADDING_MD,
      top: 20,
      bottom: 14
    })
    .backgroundColor(Color.White)
    .borderRadius(AppSize.RADIUS_LG)
  }

  @Builder
  RecommendSkeletonCard() {
    Column({ space: 14 }) {
      Row({ space: 12 }) {
        Column()
          .width(52)
          .height(52)
          .borderRadius(14)
          .backgroundColor(AppColors.BG);
        Column({ space: 6 }) {
          Row()
            .width('70%')
            .height(16)
            .borderRadius(4)
            .backgroundColor(AppColors.BG);
          Row()
            .width('50%')
            .height(12)
            .borderRadius(4)
            .backgroundColor(AppColors.BG);
        }
        .layoutWeight(1);
      }
      .width('100%')
      Column()
        .width('100%')
        .height(1)
        .backgroundColor(AppColors.DIVIDER);
      Row()
        .width('60%')
        .height(14)
        .borderRadius(4)
        .backgroundColor(AppColors.BG);
    }
    .width('100%')
    .padding(AppSize.PADDING_MD)
    .backgroundColor('#F8FAFC')
    .borderRadius(16)
  }

  @Builder
  RecommendTeamCard(t: TeamItemModel) {
    Column({ space: 14 }) {
      Row({ space: 12 }) {
        Column() {
          Text(this.getSubjectIcon(t.subject))
            .fontSize(24)
        }
        .width(52)
        .height(52)
        .backgroundColor(this.getSubjectColor(t.subject))
        .borderRadius(14)
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)

        Column({ space: 6 }) {
          Text(t.name)
            .fontSize(16)
            .fontWeight(FontWeight.Medium)
            .fontColor(AppColors.TEXT_PRIMARY)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .width('100%')

          Row({ space: 8 }) {
            Text(t.subject)
              .fontSize(12)
              .fontColor(AppColors.PRIMARY)
              .backgroundColor('#E8F0FF')
              .padding({ left: 10, right: 10, top: 3, bottom: 3 })
              .borderRadius(10)

            Row({ space: 4 }) {
              Circle()
                .width(6)
                .height(6)
                .fill(AppColors.SUCCESS)
              Text(`${t.onlineCount}人在线`)
                .fontSize(12)
                .fontColor(AppColors.SUCCESS)
            }
            .padding(5)
            .borderRadius(5)
            .backgroundColor('#ffeaf6f5')
          }
          .width('100%')
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)
      }
      .width('100%')

      Row({ space: 0 }) {
        Column({ space: 2 }) {
          Text(`${t.memberCount}`)
            .fontSize(20)
            .fontWeight(FontWeight.Bold)
            .fontColor(AppColors.TEXT_PRIMARY)
          Text(`成员/${t.maxMembers}`)
            .fontSize(12)
            .fontColor(AppColors.TEXT_SECONDARY)
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Center)

        Column({ space: 2 }) {
          Text(`${t.checkinRate.toFixed(0)}%`)
            .fontSize(20)
            .fontWeight(FontWeight.Bold)
            .fontColor('#ff70ccc8')
          Text('打卡率')
            .fontSize(12)
            .fontColor(AppColors.TEXT_SECONDARY)
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Center)

        Column({ space: 2 }) {
          Text(`${t.totalCheckins}`)
            .fontSize(20)
            .fontWeight(FontWeight.Bold)
            .fontColor('#FF9F43')
          Text('总打卡')
            .fontSize(12)
            .fontColor(AppColors.TEXT_SECONDARY)
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Center)
      }
      .width('100%')

      if (t.joinStatus === '待审核') {
        Text('待审核')
          .fontSize(15)
          .fontWeight(FontWeight.Medium)
          .fontColor(AppColors.WARNING)
          .width('100%')
          .height(44)
          .backgroundColor('#FFF3E8')
          .borderRadius(22)
          .textAlign(TextAlign.Center)
      } else {
        Text('申请加入（需审核）')
          .fontSize(15)
          .fontWeight(FontWeight.Medium)
          .fontColor(Color.White)
          .width('100%')
          .height(44)
          .backgroundColor(AppColors.PRIMARY)
          .borderRadius(22)
          .textAlign(TextAlign.Center)
          .onClick(() => this.joinTeam(t))
      }
    }
    .width('100%')
    .padding(AppSize.PADDING_MD)
    .backgroundColor('#F8FAFC')
    .borderRadius(16)
  }

  @Builder
  EmptyMyTeams() {
    Column({ space: 12 }) {
      Text('🤝')
        .fontSize(48)
      Text('你还没有加入任何小队')
        .fontSize(15)
        .fontWeight(FontWeight.Medium)
        .fontColor(AppColors.TEXT_PRIMARY)
      Text('去推荐小队加入，或自己创建一个吧')
        .fontSize(13)
        .fontColor(AppColors.TEXT_HINT)
    }
    .width('100%')
    .margin({ left: AppSize.PADDING_MD, right: AppSize.PADDING_MD, bottom: AppSize.PADDING_MD })
    .padding({ top: 32, bottom: 32 })
    .backgroundColor('#F8FAFC')
    .borderRadius(16)
  }

  @Builder
  EmptyRecommended() {
    Column({ space: 8 }) {
      Text('🔍')
        .fontSize(36)
      Text('暂无推荐小队')
        .fontSize(14)
        .fontColor(AppColors.TEXT_HINT)
      Text('换个科目看看吧')
        .fontSize(12)
        .fontColor(AppColors.TEXT_HINT)
    }
    .width('100%')
    .padding({ top: 24, bottom: 24 })
    .backgroundColor('#F8FAFC')
    .borderRadius(16)
  }

  @Builder
  CreateSheet() {
    Column() {
      Row() {
        Text('创建备考小队')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor(AppColors.TEXT_PRIMARY)
          .layoutWeight(1)
        Text('✕')
          .fontSize(20)
          .fontColor(AppColors.TEXT_HINT)
          .onClick(() => {
            this.showCreate = false;
          })
      }
      .width('100%')
      .margin({ bottom: 20 })

      Column({ space: 8 }) {
        Text('小队名称')
          .fontSize(13)
          .fontColor(AppColors.TEXT_SECONDARY)
          .width('100%')
        TextInput({ placeholder: '如：高数冲刺小队' })
          .fontSize(14)
          .width('100%')
          .height(44)
          .backgroundColor('#F2F5FA')
          .borderRadius(AppSize.RADIUS_MD)
          .padding({ left: 14, right: 14 })
          .onChange((v: string) => {
            this.createName = v.substring(0, 20);
          })
        Row() {
          Text('最多20字')
            .fontSize(11)
            .fontColor(AppColors.TEXT_HINT)
            .layoutWeight(1)
          Text(`${this.createName.length}/20`)
            .fontSize(11)
            .fontColor(this.createName.length > 18 ? AppColors.WARNING : AppColors.TEXT_HINT)
        }
        .width('100%')
      }
      .width('100%')
      .margin({ bottom: 16 })

      Column({ space: 8 }) {
        Text('关联科目')
          .fontSize(13)
          .fontColor(AppColors.TEXT_SECONDARY)
          .width('100%')
        Flex({ wrap: FlexWrap.Wrap, justifyContent: FlexAlign.Start }) {
          ForEach(SUBJECT_LIST.slice(1), (s: string) => {
            Row({ space: 4 }) {
              Text(s)
                .fontSize(13)
                .fontColor(this.createSubject === s ? AppColors.PRIMARY : AppColors.TEXT_PRIMARY)
            }
            .padding({ left: 14, right: 14, top: 8, bottom: 8
            })
            .margin({ right: 10, bottom: 10 })
            .backgroundColor(this.createSubject === s ? this.getSubjectColor(s) : '#F2F5FA')

            .borderRadius(16)
            .onClick(() => {
              this.createSubject = s;
            })
          })
        }
        .width('100%')
      }
      .width('100%')
      .margin({ bottom: 16 })

      Column({ space: 8 }) {
        Text('小队简介')
          .fontSize(13)
          .fontColor(AppColors.TEXT_SECONDARY)
          .width('100%')
        TextArea({ placeholder: '简单介绍小队目标和学习氛围...' })
          .fontSize(13)
          .width('100%')
          .height(80)
          .backgroundColor('#F2F5FA')
          .borderRadius(AppSize.RADIUS_MD)
          .padding(AppSize.PADDING_SM)
          .onChange((v: string) => {
            this.createDesc = v.substring(0, 100);
          })
        Row() {
          Text('最多100字')
            .fontSize(11)
            .fontColor(AppColors.TEXT_HINT)
            .layoutWeight(1)
          Text(`${this.createDesc.length}/100`)
            .fontSize(11)
            .fontColor(this.createDesc.length > 90 ? AppColors.WARNING : AppColors.TEXT_HINT)
        }
        .width('100%')
      }
      .width('100%')
      .margin({ bottom: 16 })

      Row() {
        Column({ space: 4 }) {
          Text('加入需要审核')
            .fontSize(14)
            .fontColor(AppColors.TEXT_PRIMARY)
          Text('审核通过后才能加入小队')
            .fontSize(12)
            .fontColor(AppColors.TEXT_HINT)
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)
        Toggle({ type: ToggleType.Switch, isOn: this.createNeedApproval })
          .onChange((v: boolean) => {
            this.createNeedApproval = v;
          })
          .selectedColor(AppColors.PRIMARY)
      }
      .width('100%')
      .padding({ left: 14, right: 14, top: 12, bottom: 12 })
      .backgroundColor('#F8FAFC')
      .borderRadius(AppSize.RADIUS_MD)

      Button(this.creating ? '创建中...' : '创建小队')
        .fontSize(16)
        .fontWeight(FontWeight.Medium)
        .height(46)
        .width('100%')
        .backgroundColor(AppColors.PRIMARY)
        .borderRadius(23)
        .margin({ top: 24, bottom: 18 })
        .enabled(!this.creating)
        .onClick(() => this.doCreate())
    }
    .width('100%')
    .padding(AppSize.PADDING_LG)
    .backgroundColor(Color.White)
    .borderRadius({ topLeft: AppSize.RADIUS_XL, topRight: AppSize.RADIUS_XL })
  }

  @Builder
  Loading() {
    Column() {
      LoadingProgress()
        .color(AppColors.PRIMARY)
        .width(40)
        .height(40)
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
      Text('😵')
        .fontSize(48)
      Text('加载失败')
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
          await this.load();
        })
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .backgroundColor(AppColors.BG)
  }

  build() {
    Stack({ alignContent: Alignment.Bottom }) {
      Column() {
        this.Header()

        if (this.pageState === 'LOADING') {
          this.Loading()
        } else if (this.pageState === 'ERROR') {
          this.ErrorView()
        } else {
          Column() {
            this.SubjectFilter()
          }

          Refresh({ refreshing: this.isRefreshing, friction: 100 }) {
            Scroll() {
              Column({ space: 16 }) {
                this.MyTeamSection()

                this.CreateTeamButton()


                this.RecommendSection()
              }
              .width('100%')
              .backgroundColor(AppColors.BG)
            }
            .layoutWeight(1)
            .width('100%')
            .scrollBar(BarState.Off)
            .edgeEffect(EdgeEffect.Spring)
          }
          .padding({ top: 10, bottom: 10 ,left:10,right:10})
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
      .backgroundColor(AppColors.BG)

      if (this.showCreate) {
        Column()
          .width('100%')
          .height('100%')
          .backgroundColor('rgba(0,0,0,0.5)')
          .onClick(() => {
            this.showCreate = false;
          })
      }
      if (this.showCreate) {
        Scroll() {
          this.CreateSheet()
        }
        .width('100%')
        .scrollBar(BarState.Off)
      }
    }
    .width('100%')
    .height('100%')
  }
}