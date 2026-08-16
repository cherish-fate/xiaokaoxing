import { promptAction } from '@kit.ArkUI';
import { AppColors } from '../utils/Constants';
import { ToastUtil } from '../utils/ToastUtil';
import { LoadingView, ErrorView } from '../components/StateViews';
import { RouterUtil } from '../utils/RouterUtil';
import { MeNotificationSettingsModel } from '../model/MeModel';
import { meRepository } from '../repository/MeRepository';
import { UpdateNotificationSettingsRequest } from '../api/ApiService';

enum PageState {
  LOADING = 'LOADING',
  CONTENT = 'CONTENT',
  ERROR = 'ERROR'
}

@Entry
@Component
struct NotificationSettingsPage {
  @State pageState: PageState = PageState.LOADING;
  @State errorMsg: string = '';
  @State examReminder: boolean = true;
  @State checkinReminder: boolean = true;
  @State originalExamReminder: boolean = true;
  @State originalCheckinReminder: boolean = true;
  @State isSaving: boolean = false;

  aboutToAppear(): void {
    this.loadData();
  }

  private async loadData(): Promise<void> {
    this.pageState = PageState.LOADING;
    const res = await meRepository.loadNotificationSettings();
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
    const data: MeNotificationSettingsModel = res.data;
    this.examReminder = data.examReminder;
    this.checkinReminder = data.checkinReminder;
    this.originalExamReminder = data.examReminder;
    this.originalCheckinReminder = data.checkinReminder;
    this.pageState = PageState.CONTENT;
  }

  private onRetry(): void {
    this.loadData();
  }

  private onBack(): void {
    if (this.isSaving) return;
    RouterUtil.back();
  }

  private isDirty(): boolean {
    return (this.examReminder !== this.originalExamReminder
      || this.checkinReminder !== this.originalCheckinReminder);
  }

  private onExamReminderChange(val: boolean): void {
    this.examReminder = val;
  }

  private onCheckinReminderChange(val: boolean): void {
    this.checkinReminder = val;
  }

  private async onSaveClick(): Promise<void> {
    if (this.isSaving) return;
    if (!this.isDirty()) {
      ToastUtil.show('暂无改动');
      RouterUtil.back();
      return;
    }
    await this.doSave();
  }

  private async doSave(): Promise<void> {
    if (this.isSaving) return;
    this.isSaving = true;
    ToastUtil.show('保存中...');
    const req: UpdateNotificationSettingsRequest = {};
    req.exam_reminder = this.examReminder;
    req.checkin_reminder = this.checkinReminder;
    const res = await meRepository.updateNotificationSettings(req);
    this.isSaving = false;
    if (res.code === 401) {
      ToastUtil.show('登录已过期，请重新登录');
      setTimeout(() => RouterUtil.toLogin(), 800);
      return;
    }
    if (!res.success || !res.data) {
      ToastUtil.show(res.message || '保存失败');
      return;
    }
    const saved: MeNotificationSettingsModel = res.data;
    this.originalExamReminder = saved.examReminder;
    this.originalCheckinReminder = saved.checkinReminder;
    ToastUtil.show(res.message || '保存成功');
    setTimeout(() => RouterUtil.back(), 500);
  }

  @Builder
  NavBar() {
    Row() {
      Row() {
        Text('‹')
          .fontSize(24)
          .fontWeight(FontWeight.Medium)
          .fontColor(AppColors.TEXT_PRIMARY)
      }
      .width(40)
      .height(40)
      .borderRadius(12)
      .justifyContent(FlexAlign.Center)
      .onClick(() => this.onBack())

      Text('通知设置')
        .fontSize(17)
        .fontWeight(FontWeight.Bold)
        .fontColor(AppColors.TEXT_PRIMARY)
        .layoutWeight(1)
        .textAlign(TextAlign.Center)
        .maxLines(1)
        .textOverflow({overflow:TextOverflow.Ellipsis})

      Row() {
        if (this.isSaving) {
          Text('...')
            .fontSize(14)
            .fontColor(AppColors.TEXT_HINT)
        } else {
          Text('保存')
            .fontSize(14)
            .fontWeight(FontWeight.Medium)
            .fontColor(AppColors.PRIMARY)
            .padding({ left: 8, right: 8 })
        }
      }
      .onClick(() => this.onSaveClick())
    }
    .width('100%')
    .height(56)
    .padding({ left: 8, right: 8 })
    .backgroundColor(Color.White)
  }

  @Builder
  TipCard() {
    Row({ space: 12 }) {
      Column() {
        Text('🔔')
          .fontSize(20)
      }
      .width(40)
      .height(40)
      .borderRadius(12)
      .justifyContent(FlexAlign.Center)
      .backgroundColor('rgba(255,255,255,0.25)')

      Column({ space: 2 }) {
        Text('通知提醒')
          .fontSize(15)
          .fontWeight(FontWeight.Medium)
          .fontColor('#FFFFFF')
        Text('开启后将在指定时间推送通知，助你不错过重要事项')
          .fontSize(12)
          .fontColor('rgba(255,255,255,0.85)')
          .lineHeight(16)
          .maxLines(2)
          .textOverflow({overflow:TextOverflow.Ellipsis})
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 20, bottom: 20 })
    .borderRadius(18)
    .linearGradient({
      direction: GradientDirection.RightBottom,
      colors: [[0x5B8BFF, 0.0], [0x4A7FFF, 1.0]]
    })
    .shadow({ radius: 12, color: 'rgba(74,127,255,0.25)' })
  }

  @Builder
  SectionLabel(title: string) {
    Text(title)
      .fontSize(13)
      .fontWeight(FontWeight.Bold)
      .fontColor(AppColors.TEXT_SECONDARY)
      .margin({ left: 4, bottom: 8, top: 0 })
  }

  @Builder
  ToggleItem(icon: string, iconBg: ResourceColor, label: string, desc: string,
    value: boolean, onChange: (v: boolean) => void) {
    Row({ space: 12 }) {
      Column() {
        Text(icon)
          .fontSize(16)
      }
      .width(36)
      .height(36)
      .borderRadius(12)
      .justifyContent(FlexAlign.Center)
      .backgroundColor(iconBg)

      Column({ space: 2 }) {
        Text(label)
          .fontSize(15)
          .fontWeight(FontWeight.Medium)
          .fontColor(AppColors.TEXT_PRIMARY)
        Text(desc)
          .fontSize(12)
          .fontColor(AppColors.TEXT_HINT)
          .lineHeight(16)
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)

      Toggle({ type: ToggleType.Switch, isOn: value })
        .onChange((val: boolean) => onChange(val))
        .selectedColor(AppColors.PRIMARY)
        .switchPointColor('#FFFFFF')
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 16, bottom: 16 })
  }

  @Builder
  SettingsCardContent() {
    this.ToggleItem(
      '📋',
      '#FFF4E6',
      '考试提醒',
      '考试前 1 天和当天早上推送提醒',
      this.examReminder,
      (v: boolean) => this.onExamReminderChange(v)
    )
    Divider()
      .color(AppColors.DIVIDER)
      .strokeWidth(1)
      .margin({ left: 16, right: 16 })
    this.ToggleItem(
      '✅',
      '#E8F8EE',
      '打卡提醒',
      '每日 21:00 提醒你完成今日打卡',
      this.checkinReminder,
      (v: boolean) => this.onCheckinReminderChange(v)
    )
  }

  @Builder
  NoticeBar() {
    Row({ space: 8 }) {
      Text('💡')
        .fontSize(12)
        .fontColor(AppColors.PRIMARY)
      Text('请确保已在系统设置中允许校考星发送通知，否则无法收到推送提醒。')
        .fontSize(11)
        .fontColor(AppColors.PRIMARY)
        .lineHeight(16)
        .layoutWeight(1)
    }
    .width('100%')
    .padding({ left: 14, right: 14, top: 12, bottom: 12 })
    .backgroundColor('#EFF4FF')
    .borderRadius(12)
  }

  @Builder
  SaveButton() {
    Text('保存设置')
      .fontSize(16)
      .fontWeight(FontWeight.Medium)
      .fontColor('#FFFFFF')
      .width('100%')
      .height(48)
      .textAlign(TextAlign.Center)
      .borderRadius(999)
      .linearGradient({
        direction: GradientDirection.RightBottom,
        colors: [[0x5B8BFF, 0.0], [0x4A7FFF, 1.0]]
      })
      .shadow({ radius: 12, color: 'rgba(74,127,255,0.30)' })
      .onClick(() => this.onSaveClick())
  }

  @Builder
  ContentView() {
    Column({ space: 16 }) {
      this.TipCard()

      Column({ space: 0 }) {
        this.SectionLabel('提醒事项')
        Column() {
          this.SettingsCardContent()
        }
        .width('100%')
        .backgroundColor(AppColors.CARD)
        .borderRadius(18)
        .border({ width: 1, color: AppColors.DIVIDER })
        .shadow({ radius: 12, color: 'rgba(0,0,0,0.04)' })
      }
      .width('100%')

      this.NoticeBar()

      this.SaveButton()
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 12, bottom: 24 })
  }

  build() {
    Column() {
      this.NavBar()
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
        Scroll() {
          this.ContentView()
        }
        .scrollBar(BarState.Off)
        .width('100%')
        .layoutWeight(1)
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(AppColors.BG)
  }
}
