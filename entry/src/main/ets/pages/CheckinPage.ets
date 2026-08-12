import { AppColors, AppSize } from '../utils/Constants';
import { ToastUtil } from '../utils/ToastUtil';
import { RouterUtil } from '../utils/RouterUtil';
import { checkinRepository } from '../repository/CheckinRepository';
import { CheckinSubmitRequest } from '../api/ApiService';
import {
  TodayCheckinModel,
  RankingModel,
  RankUserModel
} from '../model/CheckinModel';

const SUBJECT_OPTIONS: string[] = ['高等数学', '大学英语', '线性代数', '数据结构', '+ 其他'];
const DURATION_OPTIONS: string[] = ['30min', '1h', '2h', '3h+'];
const QUICK_TAGS: string[] = ['🤔 有进步', '❓ 有疑问', '🎯 达成目标'];

@Entry
@Component
struct CheckinPage {
  @State pageState: string = 'LOADING';
  @State errorMsg: string = '';
  @State today: TodayCheckinModel = TodayCheckinModel.empty();
  @State ranking: RankingModel = RankingModel.empty();
  @State submitting: boolean = false;

  @State selSubjects: string[] = [];
  @State selDuration: string = '';
  @State selTags: string[] = [];
  @State selNote: string = '';

  async aboutToAppear(): Promise<void> {
    this.pageState = 'LOADING';
    await this.loadAll();
  }

  private async loadAll(): Promise<void> {
    const result = await Promise.all([
      checkinRepository.loadTodayStatus(),
      checkinRepository.loadRanking(50)
    ]);
    const todayRes = result[0];
    const rankRes = result[1];

    if (todayRes.code === 401) {
      this.pageState = 'ERROR';
      this.errorMsg = todayRes.message || '登录已过期';
      setTimeout(() => RouterUtil.toLogin(), 800);
      return;
    }
    if (todayRes.success && todayRes.data) this.today = todayRes.data;
    if (rankRes.success && rankRes.data) this.ranking = rankRes.data;
    this.pageState = 'CONTENT';
  }

  private toggleSubject(s: string) {
    const idx = this.selSubjects.indexOf(s);
    if (idx >= 0) {
      this.selSubjects.splice(idx, 1);
    } else {
      this.selSubjects.push(s);
    }
  }

  private toggleTag(t: string) {
    const idx = this.selTags.indexOf(t);
    if (idx >= 0) {
      this.selTags.splice(idx, 1);
    } else {
      this.selTags.push(t);
    }
  }

  private async doSubmit() {
    if (this.submitting) return;
    if (this.today.hasCheckedIn) {
      ToastUtil.show('今日已打卡');
      return;
    }
    this.submitting = true;
    const req: CheckinSubmitRequest = {
      subjects: this.selSubjects.length > 0 ? this.selSubjects : undefined,
      duration: this.selDuration || undefined,
      note: this.selNote.length > 0 ? this.selNote : undefined,
      tags: this.selTags.length > 0 ? this.selTags : undefined
    };
    const res = await checkinRepository.submitCheckin(req);
    this.submitting = false;
    if (res.code === 409) {
      ToastUtil.show(res.message || '今日已打卡');
      await this.loadAll();
      return;
    }
    if (res.code === 401) {
      setTimeout(() => RouterUtil.toLogin(), 800);
      return;
    }
    if (!res.success || !res.data) {
      ToastUtil.show(res.message || '打卡失败');
      return;
    }
    ToastUtil.show(res.message || '打卡成功！');
    this.selSubjects = [];
    this.selDuration = '';
    this.selTags = [];
    this.selNote = '';
    await this.loadAll();
  }

  private isMyUser(user: RankUserModel): boolean {
    return this.ranking.myRank.rank > 0
      && this.ranking.myRank.userId > 0
      && this.ranking.myRank.userId === user.userId;
  }

  @Builder
  Header() {
    Stack({ alignContent: Alignment.Top }) {
      Column() {
        Row({ space: 8 }) {
          Image($r('app.media.community_checkin'))
            .width(20)
          Text('每日打卡')
            .fontSize(20)
            .fontWeight(FontWeight.Bold)
            .fontColor(AppColors.TEXT_PRIMARY)
        }
        .justifyContent(FlexAlign.Center)

        Text('今日加油，坚持就是胜利!')
          .fontSize(13)
          .fontColor(AppColors.TEXT_SECONDARY)
          .textAlign(TextAlign.Center)
          .padding({ bottom: 12, top: 2 })
      }
      .width('100%')
      .alignItems(HorizontalAlign.Center)

      Row() {
        Image($r('app.media.examDetail_back'))
          .width(25)
          .height(25)
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
  StatusCard() {
    Row({ space: 14 }) {
      Text(this.today.hasCheckedIn ? '🎊' : '🔥')
        .fontSize(48)
        .width(72)
        .height(72)
        .textAlign(TextAlign.Center)

      Column({ space: 6 }) {
        Text(this.today.hasCheckedIn ? '已打卡' : '今日还未打卡')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor(Color.White)
        Text(this.today.hasCheckedIn
          ? `🎊 连续打卡${this.today.continuousDays}天，继续保持！`
          : `已连续打卡${this.today.continuousDays}天，再接再厉！`)
          .fontSize(13)
          .fontColor('rgba(255,255,255,0.85)')
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)
    }
    .width('100%')
    .padding({ left: 20, right: 20, top: 22, bottom: 22 })
    .linearGradient({
      direction: GradientDirection.RightBottom,
      colors: this.today.hasCheckedIn
        ? [['#38CFC9', 0], ['#4A7FFF', 1]]
        : [['#5B8BFF', 0], ['#4A7FFF', 1]]
    })
    .borderRadius(AppSize.RADIUS_LG)
    .shadow({ radius: 12, color: 'rgba(74,127,255,0.25)', offsetY: 6 })
  }

  @Builder
  SectionTitle(icon: string, title: string, optional: string) {
    Row() {
      Row({ space: 4 }) {
        Text(icon)
          .fontSize(16)
        Text(title)
          .fontSize(15)
          .fontWeight(FontWeight.Medium)
          .fontColor(AppColors.TEXT_PRIMARY)
      }
      .layoutWeight(1)
      Text(optional)
        .fontSize(12)
        .fontColor(AppColors.TEXT_HINT)
    }
    .width('100%')
  }

  @Builder
  SubjectSection() {
    Column({ space: 12 }) {
      this.SectionTitle('📚', '学习科目', '(可选)')

      Flex({ wrap: FlexWrap.Wrap, justifyContent: FlexAlign.Start }) {
        ForEach(SUBJECT_OPTIONS, (s: string) => {
          Row({ space: 4 }) {
            if (this.selSubjects.indexOf(s) >= 0) {
              Text('✓')
                .fontSize(13)
                .fontColor(AppColors.PRIMARY)
            }
            Text(s)
              .fontSize(14)
              .fontColor(this.selSubjects.indexOf(s) >= 0 ? AppColors.PRIMARY : AppColors.TEXT_PRIMARY)
          }
          .padding({ left: 14, right: 14, top: 10, bottom: 10 })
          .margin({ right: 10, bottom: 10 })
          .backgroundColor(this.selSubjects.indexOf(s) >= 0 ? '#E8F0FF' : '#F2F5FA')
          .borderRadius(18)
          .onClick(() => this.toggleSubject(s))
        })
      }
      .width('100%')
    }
    .width('100%')
    .padding(AppSize.PADDING_LG)
    .backgroundColor(Color.White)
    .borderRadius(AppSize.RADIUS_LG)
  }

  @Builder
  DurationSection() {
    Column({ space: 12 }) {
      this.SectionTitle('⏱', '学习时长', '(可选)')

      Row({ space: 10 }) {
        ForEach(DURATION_OPTIONS, (d: string) => {
          Text(d)
            .fontSize(14)
            .fontColor(this.selDuration === d ? AppColors.PRIMARY : AppColors.TEXT_PRIMARY)
            .padding({ left: 22, right: 22, top: 10, bottom: 10 })
            .backgroundColor(this.selDuration === d ? '#E8F0FF' : '#F2F5FA')
            .borderRadius(18)
            .onClick(() => { this.selDuration = d; })
        })
      }
      .width('100%')
    }
    .width('100%')
    .padding(AppSize.PADDING_LG)
    .backgroundColor(Color.White)
    .borderRadius(AppSize.RADIUS_LG)
  }

  @Builder
  NoteSection() {
    Column({ space: 12 }) {
      Row() {
        Row({ space: 4 }) {
          Text('✏️')
            .fontSize(16)
          Text('今日备注')
            .fontSize(15)
            .fontWeight(FontWeight.Medium)
            .fontColor(AppColors.TEXT_PRIMARY)
        }
        .layoutWeight(1)
        Text('(可选)')
          .fontSize(12)
          .fontColor(AppColors.TEXT_HINT)

        Text(`${this.selNote.length}/100`)
          .fontSize(12)
          .fontColor(AppColors.TEXT_HINT)
      }
      .width('100%')

      TextArea({ placeholder: '记录今天的学习收获或疑问...' })
        .fontSize(14)
        .width('100%')
        .height(100)
        .backgroundColor('#F2F5FA')
        .borderRadius(12)
        .padding(12)
        .onChange((v: string) => { this.selNote = v.substring(0, 100); })

      Flex({ wrap: FlexWrap.Wrap, justifyContent: FlexAlign.Start }) {
        ForEach(QUICK_TAGS, (t: string) => {
          Text(t)
            .fontSize(13)
            .padding({ left: 14, right: 14, top: 8, bottom: 8 })
            .margin({ right: 10, bottom: 8 })
            .backgroundColor(this.selTags.indexOf(t) >= 0 ? '#FFF3E8' : '#F2F5FA')
            .fontColor(this.selTags.indexOf(t) >= 0 ? AppColors.WARNING : AppColors.TEXT_SECONDARY)
            .borderRadius(14)
            .onClick(() => this.toggleTag(t))
        })
      }
      .width('100%')
    }
    .width('100%')
    .padding(AppSize.PADDING_LG)
    .backgroundColor(Color.White)
    .borderRadius(AppSize.RADIUS_LG)
  }

  @Builder
  RankingItem(user: RankUserModel) {
    Row({ space: 12 }) {
      Column() {
        if (user.rank <= 3) {
          Text(['🥇', '🥈', '🥉'][user.rank - 1])
            .fontSize(18)
        } else {
          Text(`${user.rank}`)
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .fontColor(AppColors.TEXT_SECONDARY)
        }
      }
      .width(32)
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)

      Stack() {
        Column() {
          Text(user.nickname.charAt(0))
            .fontSize(14)
            .fontColor(Color.White)
        }
        .width(40)
        .height(40)
        .borderRadius(20)
        .backgroundColor(user.isMe ? '#ffeaf0fe' : '#ffeaf6f5')
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)

        Column() {
          Text(`${user.rank}`)
            .fontSize(10)
            .fontColor(Color.White)
            .fontWeight(FontWeight.Bold)
        }
        .width(16)
        .height(16)
        .borderRadius(8)
        .backgroundColor(user.rank === 1 ? '#FFD700'
          : user.rank === 2 ? '#C0C0C0'
          : user.rank === 3 ? '#CD7F32' : AppColors.PRIMARY)
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
        .align(Alignment.BottomEnd)
        .margin({ right: 0 })
      }
      .width(40)
      .height(40)

      Column({ space: 4 }) {
        Row() {
          Text(user.nickname)
            .fontSize(15)
            .fontWeight(FontWeight.Medium)
            .fontColor(AppColors.TEXT_PRIMARY)
            .layoutWeight(1)
          Text(`${user.totalDays}🔥`)
            .fontSize(14)
            .fontWeight(FontWeight.Medium)
            .fontColor('#ff6a8ff8')
        }
        .width('100%')
        Text(`连续打卡${user.continuousDays}天`)
          .fontSize(12)
          .fontColor(AppColors.TEXT_HINT)
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)
    }
    .width('100%')
    .padding({ top: 12, bottom: 12 })
  }

  @Builder
  RankingSection() {
    Column({ space: 8 }) {
      Row() {
        Row({ space: 4 }) {
          Text('🏆')
            .fontSize(18)
          Text('本校打卡排行 TOP5')
            .fontSize(17)
            .fontWeight(FontWeight.Medium)
            .fontColor(AppColors.TEXT_PRIMARY)
        }
        .layoutWeight(1)
      }
      .width('100%')
      .margin({ bottom: 4 })

      Column() {
        ForEach(this.ranking.list.slice(0, 5), (user: RankUserModel, idx: number) => {
          Column() {
            if (idx > 0) {
              Divider()
                .color(AppColors.DIVIDER)
                .strokeWidth(1)
            }
            this.RankingItem(user)
          }
          .width('100%')
          .backgroundColor(this.isMyUser(user) ? '#F8FAFF' : Color.Transparent)
          .borderRadius(this.isMyUser(user) ? 12 : 0)
          .padding(this.isMyUser(user) ? { left: 8, right: 8 } : {})
        })
      }
      .width('100%')

      if (this.ranking.myRank && this.ranking.myRank.rank > 5) {
        Column() {
          Divider()
            .color(AppColors.DIVIDER)
            .strokeWidth(1)
            .margin({ top: 4 })

          this.RankingItem(this.ranking.myRank)
        }
        .width('100%')
        .backgroundColor('#F8FAFF')
        .borderRadius(12)
        .padding({ left: 8, right: 8 })
        .margin({ top: 8 })
      }
    }
    .width('100%')
    .padding(AppSize.PADDING_LG)
    .backgroundColor(Color.White)
    .borderRadius(AppSize.RADIUS_LG)
  }

  @Builder
  SubmitBar() {
    Row() {
      Button() {
        Row({ space: 6 }) {
          Text(this.today.hasCheckedIn ? '今日已打卡' : '确认打卡')
            .fontSize(16)
            .fontWeight(FontWeight.Medium)
            .fontColor(Color.White)
        }
      }
      .width('100%')
      .height(52)
      .backgroundColor(this.today.hasCheckedIn ? AppColors.SUCCESS : AppColors.PRIMARY)
      .borderRadius(26)
      .enabled(!this.submitting && !this.today.hasCheckedIn)
      .onClick(() => this.doSubmit())
    }
    .width('100%')
    .padding({ left: AppSize.PADDING_MD, right: AppSize.PADDING_MD, top: 12, bottom: 20 })
    .backgroundColor(Color.White)
    .shadow({ radius: 8, color: 'rgba(0,0,0,0.06)', offsetY: -2 })
  }

  @Builder
  Loading() {
    Column() {
      LoadingProgress().color(AppColors.PRIMARY)
    }.width('100%').height('100%').justifyContent(FlexAlign.Center)
      .backgroundColor(AppColors.BG)
  }

  @Builder
  ErrorView() {
    Column({ space: 12 }) {
      Text('😵')
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
          await this.loadAll();
        })
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .backgroundColor(AppColors.BG)
  }

  build() {
    Column() {
      this.Header()

      if (this.pageState === 'LOADING') {
        this.Loading()
      } else if (this.pageState === 'ERROR') {
        this.ErrorView()
      } else {
        Scroll() {
          Column({ space: 12 }) {
            this.StatusCard()
            this.SubjectSection()
            this.DurationSection()
            this.NoteSection()
            this.RankingSection()
          }
          .width('100%')
          .padding({ left: AppSize.PADDING_MD, right: AppSize.PADDING_MD, top: 12, bottom: 12 })
        }
        .layoutWeight(1)
        .width('100%')
        .scrollBar(BarState.Off)
        .edgeEffect(EdgeEffect.Spring)

        this.SubmitBar()
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(AppColors.BG)
  }
}
