import { AppColors, AppSize } from '../utils/Constants';
import { ToastUtil } from '../utils/ToastUtil';
import { RouterUtil } from '../utils/RouterUtil';
import { DateUtil } from '../utils/DateUtil';
import { voteRepository } from '../repository/VoteRepository';
import {
  VoteItemModel,
  MyVoteRecordModel,
  PendingSubmissionModel,
  SubmitVoteRequest
} from '../model/VoteModel';

const SUBJECT_TABS = ['全部', '高数', '英语', '线代', '物理'];

@Entry
@Component
struct VotePage {
  @State pageState: string = 'LOADING';
  @State selSubject: string = '全部';
  @State list: VoteItemModel[] = [];
  @State pending: PendingSubmissionModel[] = [];
  @State myVotes: MyVoteRecordModel[] = [];
  @State votingIds: number[] = [];

  @State showSubmit: boolean = false;
  @State submitting: boolean = false;
  @State submitSubject: string = '';
  @State submitTitle: string = '';
  @State submitDesc: string = '';

  async aboutToAppear(): Promise<void> {
    this.pageState = 'LOADING';
    await this.loadAll();
  }

  private async loadAll(): Promise<void> {
    const res = await Promise.all([
      voteRepository.loadVotes(this.selSubject === '全部' ? undefined : this.selSubject),
      voteRepository.loadPendingSubmissions(),
      voteRepository.loadMyVotes()
    ]);
    const listRes = res[0];
    const pendingRes = res[1];
    const voteRes = res[2];

    if (listRes.code === 401) { setTimeout(() => RouterUtil.toLogin(), 800); return; }
    if (listRes.success && listRes.data) this.list = listRes.data.list;
    if (pendingRes.success && pendingRes.data) this.pending = pendingRes.data.list;
    if (voteRes.success && voteRes.data) this.myVotes = voteRes.data.list;
    this.pageState = 'CONTENT';
  }

  private async vote(voteId: number) {
    if (this.votingIds.indexOf(voteId) >= 0) return;
    const idx = this.list.findIndex(v => v.id === voteId);
    if (idx < 0 || this.list[idx].hasVoted) {
      ToastUtil.show('您已投过该考点');
      return;
    }
    this.votingIds.push(voteId);
    // 乐观更新：克隆当前项并标记为已投，替换数组中对应项以触发 ForEach 重新渲染
    const oldItem: VoteItemModel = this.list[idx];
    const optimistic: VoteItemModel = new VoteItemModel(
      oldItem.id, oldItem.subject, oldItem.title, oldItem.description,
      oldItem.voteCount + 1, oldItem.confidence, oldItem.stars, true, oldItem.totalUsers
    );
    this.list = this.list.map((v, i) => i === idx ? optimistic : v);
    const res = await voteRepository.voteFor(voteId);
    const pos = this.votingIds.indexOf(voteId);
    if (pos >= 0) this.votingIds.splice(pos, 1);
    if (!res.success || !res.data) {
      if (res.code === 409) {
        // 已投过：保持已投状态，但票数回退
        const voted: VoteItemModel = new VoteItemModel(
          oldItem.id, oldItem.subject, oldItem.title, oldItem.description,
          oldItem.voteCount, oldItem.confidence, oldItem.stars, true, oldItem.totalUsers
        );
        this.list = this.list.map((v, i) => i === idx ? voted : v);
      } else {
        // 其他失败：完全回滚
        this.list = this.list.map((v, i) => i === idx ? oldItem : v);
      }
      ToastUtil.show(res.message || '投票失败');
      return;
    }
    // 成功：用服务端返回的真实数据更新
    const updated: VoteItemModel = new VoteItemModel(
      optimistic.id, optimistic.subject, optimistic.title, optimistic.description,
      res.data.voteCount, res.data.confidence, optimistic.stars, true, optimistic.totalUsers
    );
    this.list = this.list.map((v, i) => i === idx ? updated : v);
    // 我的投票记录立即增加一条
    const newRecord: MyVoteRecordModel = new MyVoteRecordModel(
      voteId, oldItem.subject, oldItem.title, res.data.voteCount, res.data.confidence,
      DateUtil.toShortDateTime(new Date().toISOString()), '会考', oldItem.totalUsers
    );
    this.myVotes = [newRecord, ...this.myVotes];
    ToastUtil.show('投票成功');
  }

  private async doSubmit() {
    if (this.submitting) return;
    if (!this.submitSubject) { ToastUtil.show('请选择科目'); return; }
    if (!this.submitTitle.trim()) { ToastUtil.show('请填写考点名称'); return; }
    this.submitting = true;
    const req: SubmitVoteRequest = {
      subject: this.submitSubject,
      title: this.submitTitle,
      description: this.submitDesc || undefined
    };
    const res = await voteRepository.submitVotePoint(req);
    this.submitting = false;
    if (!res.success || !res.data) {
      ToastUtil.show(res.message || '提交失败');
      return;
    }
    ToastUtil.show(res.message || '提交成功，等待审核');
    this.showSubmit = false;
    this.submitSubject = '';
    this.submitTitle = '';
    this.submitDesc = '';
  }

  @Builder
  Header() {
    Stack({ alignContent: Alignment.Top }) {
      Column() {
        Row({ space: 6 }) {
          Image($r('app.media.community_vote'))
            .width(20)
          Text('考点投票')
            .fontSize(20)
            .fontWeight(FontWeight.Bold)
            .fontColor(AppColors.TEXT_PRIMARY)
        }
        .justifyContent(FlexAlign.Center)

        Text('投票预测期末考点，集体智慧不踩坑')
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
    Row({ space: 8 }) {
      ForEach(SUBJECT_TABS, (s: string) => {
        Text(s)
          .fontSize(13)
          .fontWeight(this.selSubject === s ? FontWeight.Medium : FontWeight.Normal)
          .padding({ left: 16, right: 16, top: 8, bottom: 8 })
          .backgroundColor(this.selSubject === s ? AppColors.PRIMARY : '#F2F5FA')
          .fontColor(this.selSubject === s ? Color.White : AppColors.TEXT_SECONDARY)
          .borderRadius(18)
          .onClick(async () => {
            if (this.selSubject === s) return;
            this.selSubject = s;
            const res = await voteRepository.loadVotes(s === '全部' ? undefined : s);
            if (res.success && res.data) this.list = res.data.list;
          })
      })
    }
    .width('100%')
    .padding({ left: AppSize.PADDING_MD, right: AppSize.PADDING_MD, top: 10, bottom: 10 })
    .backgroundColor(Color.White)
  }

  @Builder
  VoteItemCard(v: VoteItemModel) {
    Column({ space: 10 }) {
      Row() {
        Row({ space: 8 }) {
          Text(v.subject)
            .fontSize(11)
            .fontColor(v.tagColor())
            .backgroundColor(v.tagBg())
            .padding({ left: 8, right: 8, top: 3, bottom: 3 })
            .borderRadius(10)

          Text(v.title)
            .fontSize(15)
            .fontWeight(FontWeight.Medium)
            .fontColor(AppColors.TEXT_PRIMARY)
            .layoutWeight(1)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })

          Text(`${v.voteCount}票`)
            .fontSize(13)
            .fontWeight(FontWeight.Medium)
            .fontColor(v.barColor())
        }
        .width('100%')
        .alignItems(VerticalAlign.Center)
      }

      Row({ space: 10 }) {
        Row()
          .width(`${v.confidenceWidth()}%`)
          .height(6)
          .backgroundColor(v.barColor())
          .borderRadius(3)
        Row()
          .layoutWeight(1)
          .height(6)
          .backgroundColor('#EEF0F3')
          .borderRadius(3)
      }
      .width('100%')

      Row() {
        Text(v.starsText())
          .fontSize(13)
          .fontColor('#FFB800')
        Text(`${v.computedConfidence()}% 认为会考`)
          .fontSize(12)
          .fontColor(AppColors.TEXT_HINT)
          .layoutWeight(1)
          .textAlign(TextAlign.End)
      }
      .width('100%')

      if (!v.hasVoted) {
        Button('投票')
          .fontSize(13)
          .height(32)
          .backgroundColor(v.barColor())
          .fontColor(Color.White)
          .borderRadius(16)
          .padding({ left: 20, right: 20 })
          .enabled(this.votingIds.indexOf(v.id) < 0)
          .onClick(() => this.vote(v.id))
      } else {
        Row() {
          Text('✓ 已投')
            .fontSize(12)
            .fontColor(AppColors.SUCCESS)
        }
        .width('100%')
        .padding({ top: 2, bottom: 2 })
      }
    }
    .width('100%')
    .padding(AppSize.PADDING_LG)
    .backgroundColor(Color.White)
    .borderRadius(AppSize.RADIUS_LG)
  }

  @Builder
  PendingItemCard(s: PendingSubmissionModel) {
    Column({ space: 6 }) {
      Row() {
        Text(s.subject)
          .fontSize(11)
          .fontColor(s.tagColor())
          .backgroundColor(s.tagBg())
          .padding({ left: 8, right: 8, top: 3, bottom: 3 })
          .borderRadius(10)

        Text('⏳ 审核中')
          .fontSize(11)
          .fontColor(AppColors.WARNING)
          .backgroundColor('#FFF3E8')
          .padding({ left: 8, right: 8, top: 3, bottom: 3 })
          .borderRadius(10)

        Text(`${s.createdAt} · ${s.authorName}`)
          .fontSize(11)
          .fontColor(AppColors.TEXT_HINT)
          .layoutWeight(1)
          .textAlign(TextAlign.End)
      }
      .width('100%')

      Text(`【${s.subject}】${s.title}`)
        .fontSize(14)
        .fontWeight(FontWeight.Medium)
        .fontColor(AppColors.TEXT_PRIMARY)
        .width('100%')

      if (s.description && s.description.length > 0) {
        Text(s.description)
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
  MyVoteItemCard(r: MyVoteRecordModel) {
    Column({ space: 10 }) {
      Row({ space: 8 }) {
          Text(r.subject)
            .fontSize(11)
            .fontColor(r.tagColor())
            .backgroundColor(r.tagBg())
            .padding({ left: 8, right: 8, top: 3, bottom: 3 })
            .borderRadius(10)

          Text(r.title)
            .fontSize(15)
            .fontWeight(FontWeight.Medium)
            .fontColor(AppColors.TEXT_PRIMARY)
            .layoutWeight(1)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })

        Text('✓ 已投')
          .fontSize(12)
          .fontColor(AppColors.SUCCESS)
      }
      .width('100%')

      Row({ space: 10 }) {
        Row()
          .width(`${r.confidenceWidth()}%`)
          .height(6)
          .backgroundColor(r.barColor())
          .borderRadius(3)
        Row()
          .layoutWeight(1)
          .height(6)
          .backgroundColor('#EEF0F3')
          .borderRadius(3)
      }
      .width('100%')

      Row() {
        Text(`你投了：${r.myChoice}`)
          .fontSize(12)
          .fontColor(AppColors.TEXT_SECONDARY)
        Text(`${r.computedConfidence()}% 同意`)
          .fontSize(12)
          .fontColor(AppColors.TEXT_HINT)
          .layoutWeight(1)
          .textAlign(TextAlign.End)
      }
      .width('100%')
    }
    .width('100%')
    .padding(AppSize.PADDING_LG)
    .backgroundColor(Color.White)
    .borderRadius(AppSize.RADIUS_LG)
  }

  @Builder
  SectionHeader(icon: Resource, title: string, badge: string) {
    Row() {
      Row({ space: 4 }) {
        Image(icon)
          .width(20)
        Text(title)
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .fontColor(AppColors.TEXT_PRIMARY)
      }
      .layoutWeight(1)

      if (badge && badge.length > 0) {
        Text(badge)
          .fontSize(11)
          .fontColor(Color.White)
          .backgroundColor('#FF7E02')
          .padding({ left: 8, right: 8, top: 3, bottom: 3 })
          .borderRadius(10)
      }
    }
    .width('100%')
    .padding({ left: AppSize.PADDING_MD, right: AppSize.PADDING_MD, top: 12, bottom: 8 })
    .backgroundColor(AppColors.BG)
  }

  @Builder
  EmptyTip(emoji: string, tip: string) {
    Column({ space: 6 }) {
      Text(emoji)
        .fontSize(32)
      Text(tip)
        .fontSize(13)
        .fontColor(AppColors.TEXT_HINT)
    }
    .width('100%')
    .padding({ top: 30, bottom: 30 })
    .backgroundColor(Color.White)
    .borderRadius(AppSize.RADIUS_LG)
  }

  @Builder
  SubmitSheet() {
    Column() {
      Row() {
        Text('提交新考点')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor(AppColors.TEXT_PRIMARY)
          .layoutWeight(1)
        Text('✕')
          .fontSize(20)
          .fontColor(AppColors.TEXT_HINT)
          .onClick(() => { this.showSubmit = false; })
      }
      .width('100%')
      .margin({ bottom: 20 })

      Text('关联科目')
        .fontSize(13)
        .fontColor(AppColors.TEXT_SECONDARY)
        .width('100%')
        .margin({ bottom: 8 })

      Flex({ wrap: FlexWrap.Wrap, justifyContent: FlexAlign.Start }) {
        ForEach(SUBJECT_TABS.slice(1), (s: string) => {
          Text(s)
            .fontSize(13)
            .padding({ left: 14, right: 14, top: 8, bottom: 8 })
            .margin({ right: 10, bottom: 10 })
            .backgroundColor(this.submitSubject === s ? '#E8F0FF' : '#F2F5FA')
            .fontColor(this.submitSubject === s ? AppColors.PRIMARY : AppColors.TEXT_PRIMARY)
            .borderRadius(16)
            .onClick(() => { this.submitSubject = s; })
        })
      }
      .width('100%')

      Text('考点名称（最多30字）')
        .fontSize(13)
        .fontColor(AppColors.TEXT_SECONDARY)
        .width('100%')
        .margin({ top: 16, bottom: 8 })

      TextInput({ placeholder: '如：洛必达法则求极限' })
        .fontSize(14)
        .width('100%')
        .height(44)
        .backgroundColor('#F2F5FA')
        .borderRadius(AppSize.RADIUS_MD)
        .padding({ left: 14, right: 14 })
        .onChange((v: string) => { this.submitTitle = v.substring(0, 30); })

      Text('补充说明（最多200字）')
        .fontSize(13)
        .fontColor(AppColors.TEXT_SECONDARY)
        .width('100%')
        .margin({ top: 16, bottom: 8 })

      TextArea({ placeholder: '例如：老师说必考，已连续考3年...' })
        .fontSize(13)
        .width('100%')
        .height(90)
        .backgroundColor('#F2F5FA')
        .borderRadius(AppSize.RADIUS_MD)
        .padding(AppSize.PADDING_SM)
        .onChange((v: string) => { this.submitDesc = v.substring(0, 200); })

      Text('*提交后需管理员审核，通过后才会出现在投票列表')
        .fontSize(11)
        .fontColor(AppColors.TEXT_HINT)
        .width('100%')
        .margin({ top: 10 })

      Button(this.submitting ? '提交中...' : '提交考点')
        .fontSize(16)
        .fontWeight(FontWeight.Medium)
        .height(46)
        .width('100%')
        .backgroundColor(AppColors.PRIMARY)
        .borderRadius(23)
        .margin({ top: 20, bottom: 18 })
        .enabled(!this.submitting)
        .onClick(() => this.doSubmit())
    }
    .width('100%')
    .padding(AppSize.PADDING_LG)
    .backgroundColor(Color.White)
    .borderRadius({ topLeft: AppSize.RADIUS_XL, topRight: AppSize.RADIUS_XL })
  }

  @Builder
  LoadingView() {
    Column() {
      LoadingProgress()
        .width(32)
        .height(32)
        .color(AppColors.PRIMARY)
        .margin({ bottom: AppSize.PADDING_MD });
      Text('加载中...')
        .fontSize(14)
        .fontColor(AppColors.TEXT_SECONDARY);
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center);
  }

  build() {
    Stack({ alignContent: Alignment.Bottom }) {
      Column() {
        this.Header()

        if (this.pageState === 'LOADING') {
          this.LoadingView()
        } else {
          this.SubjectFilter()

          Scroll() {
            Column({ space: 12 }) {
              this.SectionHeader($r('app.media.community_flame'), '热门投票', '')

              if (this.list.length === 0) {
                this.EmptyTip('📋', '该科目下暂无考点，成为第一个提交的人吧')
              } else {
                ForEach(this.list.slice(0, 3), (v: VoteItemModel) => {
                  this.VoteItemCard(v)
                }, (v: VoteItemModel) => `${v.id}_${v.hasVoted}`)
              }

              if (this.pending.length > 0) {
                this.SectionHeader($r('app.media.community_new'), '同学新提交（待审核）', 'NEW')

                ForEach(this.pending.slice(0, 3), (s: PendingSubmissionModel) => {
                  this.PendingItemCard(s)
                })
              }

              this.SectionHeader($r('app.media.community_myvote'), '我的投票记录', '')

              if (this.myVotes.length === 0) {
                this.EmptyTip('📭', '你还没投过任何考点')
              } else {
                ForEach(this.myVotes.slice(0, 5), (r: MyVoteRecordModel) => {
                  this.MyVoteItemCard(r)
                }, (r: MyVoteRecordModel) => `${r.voteId}`)
              }

              Column()
                .width('100%')
                .height(70)
            }
            .padding({left:10,right:10})
            .width('100%')
            .backgroundColor(AppColors.BG)
          }
          .layoutWeight(1)
          .width('100%')
          .scrollBar(BarState.Off)
          .edgeEffect(EdgeEffect.Spring)
        }
      }
      .width('100%')
      .height('100%')

      if (this.pageState === 'CONTENT') {
        Button() {
          Row({ space: 6 }) {
            Text('+ 提交新考点（需审核）')
              .fontSize(16)
              .fontWeight(FontWeight.Medium)
              .fontColor(Color.White)
          }
        }
        .width(350)
        .height(50)
        .backgroundColor(AppColors.PRIMARY)
        .borderRadius(25)
        .margin({ left: 20, right:20, bottom: 12 })
        .onClick(() => { this.showSubmit = true; })
      }

      if (this.showSubmit) {
        Column()
          .width('100%')
          .height('100%')
          .backgroundColor('rgba(0,0,0,0.5)')
          .onClick(() => { this.showSubmit = false; })
      }
      if (this.showSubmit) {
        Scroll() { this.SubmitSheet() }
          .width('100%')
          .scrollBar(BarState.Off)
      }
    }
    .width('100%')
    .height('100%')
  }
}
