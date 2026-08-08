import { router } from '@kit.ArkUI';
import { taskRepository } from '../repository/TaskRepository';
import { AppColors, AppSize } from '../utils/Constants';
import { ToastUtil } from '../utils/ToastUtil';
import { Logger } from '../utils/Logger';
import { DateUtil } from '../utils/DateUtil';
import { CreateTaskRequest } from '../api/ApiService';

const TAG = 'TaskAddPage';
const MAX_LENGTH = 200;

@CustomDialog
struct DatePickerDialog {
  controller: CustomDialogController = new CustomDialogController({ builder: () => {} });
  @Link linkedDate: Date;
  @State tempDate: Date = new Date();

  aboutToAppear(): void {
    this.tempDate = new Date(this.linkedDate.getTime());
  }

  build() {
    Column() {
      Text('选择计划日期')
        .fontSize(16)
        .fontWeight(FontWeight.Medium)
        .fontColor(AppColors.TEXT_PRIMARY)
        .margin({ top: 16, bottom: 8 })

      DatePicker({
        start: new Date('2020-01-01'),
        end: new Date('2035-12-31'),
        selected: this.tempDate
      })
        .lunar(false)
        .layoutWeight(1)
        .onChange((value: DatePickerResult) => {
          this.tempDate = new Date(value.year!, value.month!, value.day!);
        })

      Row() {
        Button('取消')
          .layoutWeight(1)
          .height(44)
          .backgroundColor(AppColors.CARD)
          .fontColor(AppColors.TEXT_SECONDARY)
          .borderRadius(AppSize.RADIUS_MD)
          .onClick(() => this.controller.close())

        Blank().width(12)

        Button('确定')
          .layoutWeight(1)
          .height(44)
          .backgroundColor(AppColors.PRIMARY)
          .fontColor(Color.White)
          .borderRadius(AppSize.RADIUS_MD)
          .onClick(() => {
            this.linkedDate = this.tempDate;
            this.controller.close();
          })
      }
      .width('100%')
      .padding({ left: 16, right: 16, bottom: 16, top: 8 })
    }
    .width('100%')
    .height(380)
    .backgroundColor(AppColors.BG)
    .borderRadius({ topLeft: 20, topRight: 20 })
  }
}

@Entry
@Component
struct TaskAddPage {
  @State taskName: string = '';
  @State planDate: Date = new Date();
  @State isSubmitting: boolean = false;

  private dateDialogCtrl: CustomDialogController = new CustomDialogController({
    builder: DatePickerDialog({
      linkedDate: $planDate
    }),
    alignment: DialogAlignment.Bottom,
    customStyle: true,
    autoCancel: true
  });

  private formatDate(d: Date): string {
    return DateUtil.format(d);
  }

  private isToday(d: Date): boolean {
    const today = new Date();
    return d.getFullYear() === today.getFullYear() &&
      d.getMonth() === today.getMonth() &&
      d.getDate() === today.getDate();
  }

  private validate(): string | null {
    if (!this.taskName || this.taskName.trim().length === 0) {
      return '请输入任务名称';
    }
    return null;
  }

  private buildRequest(): CreateTaskRequest {
    const req: CreateTaskRequest = {
      task_name: this.taskName.trim(),
      is_completed: false
    };
    if (!this.isToday(this.planDate)) {
      req.plan_date = this.formatDate(this.planDate);
    }
    return req;
  }

  private async handleSave(): Promise<void> {
    if (this.isSubmitting) {
      return;
    }
    const err = this.validate();
    if (err) {
      ToastUtil.show(err);
      return;
    }
    this.isSubmitting = true;
    try {
      const req = this.buildRequest();
      const result = await taskRepository.createTask(req);
      if (result.success && result.data) {
        ToastUtil.show('任务添加成功');
        setTimeout(() => {
          try {
            router.back();
          } catch (_) {}
        }, 600);
      } else if (result.code === 401) {
        ToastUtil.show('登录已过期，请重新登录');
      } else if (result.code === 400) {
        ToastUtil.show(result.message || '任务名称不能为空');
      } else {
        ToastUtil.show(result.message || '添加失败，请重试');
      }
    } catch (e) {
      Logger.error(TAG, 'handleSave failed', e as Error);
      ToastUtil.show('网络异常，请稍后重试');
    } finally {
      this.isSubmitting = false;
    }
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

      Scroll() {
        Column({ space: 20 }) {
          this.NameField();
          this.DateField();
          this.SaveButton();
        }
        .width('100%')
        .padding({ left: 20, right: 20, top: 8, bottom: 40 })
      }
      .scrollBar(BarState.Off)
      .edgeEffect(EdgeEffect.Spring)
      .layoutWeight(1)
    }
    .width('100%')
    .height('100%')
    .backgroundColor(AppColors.BG)
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
  }

  @Builder
  TopBar() {
    Row() {
      Text('添加任务')
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .fontColor(AppColors.TEXT_PRIMARY)
      Blank()
      Image($r('app.media.examadd_cha'))
        .width(40)
        .height(40)
        .padding(10)
        .backgroundColor(AppColors.CARD)
        .borderRadius(20)
        .onClick(() => this.handleClose())
    }
    .width('100%')
    .padding({ left: 20, right: 20, top: 12, bottom: 12 })
    .alignItems(VerticalAlign.Center)
  }

  @Builder
  FieldLabel(label: string, required: boolean = false) {
    Row() {
      Text(label)
        .fontSize(14)
        .fontWeight(FontWeight.Medium)
        .fontColor(AppColors.TEXT_PRIMARY)
      if (required) {
        Text(' *')
          .fontSize(14)
          .fontColor(AppColors.DANGER)
      }
    }
    .margin({ bottom: 8 })
  }

  @Builder
  NameField() {
    Column() {
      this.FieldLabel('任务名称', true);
      Stack({ alignContent: Alignment.BottomEnd }) {
        TextInput({ placeholder: '如：复习高等数学第三章、完成英语真题一套', text: $$this.taskName })
          .width('100%')
          .height(52)
          .type(InputType.Normal)
          .maxLength(MAX_LENGTH)
          .placeholderColor(AppColors.TEXT_HINT)
          .fontSize(15)
          .fontColor(AppColors.TEXT_PRIMARY)
          .backgroundColor(AppColors.CARD)
          .borderRadius(AppSize.RADIUS_LG)
          .padding({ left: 16, right: 60 })
        Text(`${this.taskName.length}/${MAX_LENGTH}`)
          .fontSize(12)
          .fontColor(AppColors.TEXT_HINT)
          .margin({ right: 16, bottom: 6 })
      }
      .width('100%')
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
  }

  @Builder
  DateField() {
    Column() {
      this.FieldLabel('计划日期');
      Row() {
        Image($r('app.media.home_examclock'))
          .width(20)
          .fillColor('#ffd3d3d3')
        Text(this.isToday(this.planDate) ? `${this.formatDate(this.planDate)}（今天）` : this.formatDate(this.planDate))
          .fontSize(15)
          .fontColor(AppColors.TEXT_PRIMARY)
          .layoutWeight(1)
          .margin({ left: 8 })
        Text('›')
          .fontSize(18)
          .fontColor(AppColors.TEXT_HINT)
      }
      .width('100%')
      .height(52)
      .padding({ left: 16, right: 16 })
      .backgroundColor(AppColors.CARD)
      .borderRadius(AppSize.RADIUS_LG)
      .onClick(() => this.dateDialogCtrl.open())
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
  }

  @Builder
  SaveButton() {
    Button(this.isSubmitting ? '添加中...' : '添加任务')
      .width('100%')
      .height(52)
      .backgroundColor(this.isSubmitting ? AppColors.TEXT_HINT : AppColors.PRIMARY)
      .borderRadius(AppSize.RADIUS_LG)
      .fontSize(16)
      .fontWeight(FontWeight.Medium)
      .fontColor(Color.White)
      .enabled(!this.isSubmitting)
      .shadow({
        radius: 12,
        color: this.isSubmitting ? 'rgba(0,0,0,0)' : 'rgba(74,127,255,0.35)',
        offsetY: 4
      })
      .margin({ top: 12 })
      .onClick(() => this.handleSave())
  }
}
