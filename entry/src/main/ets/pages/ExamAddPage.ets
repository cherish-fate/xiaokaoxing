import { router } from '@kit.ArkUI';
import { examRepository } from '../repository/ExamRepository';
import { AppColors, AppSize } from '../utils/Constants';
import { ToastUtil } from '../utils/ToastUtil';
import { Logger } from '../utils/Logger';
import { DateUtil } from '../utils/DateUtil';
import { CreateExamRequest } from '../api/ApiService';

const TAG = 'ExamAddPage';

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
      Text('选择考试日期')
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

@CustomDialog
struct TimePickerDialog {
  controller: CustomDialogController = new CustomDialogController({ builder: () => {} });
  title: string = '选择时间';
  @Link linkedHour: number;
  @Link linkedMinute: number;
  @State tempHour: number = 9;
  @State tempMinute: number = 0;
  @State tempDate: Date =new Date()

  aboutToAppear(): void {
    this.tempHour = this.linkedHour;
    this.tempMinute = this.linkedMinute;
  }

  build() {
    Column() {
      Text(this.title)
        .fontSize(16)
        .fontWeight(FontWeight.Medium)
        .fontColor(AppColors.TEXT_PRIMARY)
        .margin({ top: 16, bottom: 8 })

      TimePicker({
        selected:  this.tempDate
      })
        .useMilitaryTime(true)
        .layoutWeight(1)
        .onChange((value: TimePickerResult) => {
          this.tempHour = value.hour;
          this.tempMinute = value.minute;
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
            this.linkedHour = this.tempHour;
            this.linkedMinute = this.tempMinute;
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
struct ExamAddPage {
  @State examName: string = '';
  @State examDate: Date = new Date();
  @State startHour: number = 9;
  @State startMinute: number = 0;
  @State endHour: number = 11;
  @State endMinute: number = 0;
  @State location: string = '';
  @State isSubmitting: boolean = false;

  private dateDialogCtrl: CustomDialogController = new CustomDialogController({
    builder: DatePickerDialog({
      linkedDate: $examDate
    }),
    alignment: DialogAlignment.Bottom,
    customStyle: true,
    autoCancel: true
  });

  private startTimeDialogCtrl: CustomDialogController = new CustomDialogController({
    builder: TimePickerDialog({
      title: '选择开始时间',
      linkedHour: $startHour,
      linkedMinute: $startMinute
    }),
    alignment: DialogAlignment.Bottom,
    customStyle: true,
    autoCancel: true
  });

  private endTimeDialogCtrl: CustomDialogController = new CustomDialogController({
    builder: TimePickerDialog({
      title: '选择结束时间',
      linkedHour: $endHour,
      linkedMinute: $endMinute
    }),
    alignment: DialogAlignment.Bottom,
    customStyle: true,
    autoCancel: true
  });

  private formatDate(d: Date): string {
    return DateUtil.format(d);
  }

  private formatTime(h: number, m: number): string {
    const hh = `${h}`.padStart(2, '0');
    const mm = `${m}`.padStart(2, '0');
    return `${hh}:${mm}`;
  }

  private validate(): string | null {
    if (!this.examName || this.examName.trim().length === 0) {
      return '请输入考试科目名称';
    }
    const startMinutes = this.startHour * 60 + this.startMinute;
    const endMinutes = this.endHour * 60 + this.endMinute;
    if (endMinutes <= startMinutes) {
      return '结束时间必须晚于开始时间';
    }
    return null;
  }

  private buildRequest(): CreateExamRequest {
    return {
      name: this.examName.trim(),
      exam_date: this.formatDate(this.examDate),
      start_time: this.formatTime(this.startHour, this.startMinute),
      end_time: this.formatTime(this.endHour, this.endMinute),
      location: this.location && this.location.trim().length > 0 ? this.location.trim() : undefined,
      is_completed: false
    };
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
      const result = await examRepository.createExam(req);
      if (result.success && result.data) {
        ToastUtil.show('考试添加成功');
        setTimeout(() => {
          try {
            router.back();
          } catch (_) {}
        }, 600);
      } else if (result.code === 401) {
        ToastUtil.show('登录已过期，请重新登录');
      } else if (result.code === 400) {
        ToastUtil.show(result.message || '提交内容不合法');
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
          this.TimeRow();
          this.LocationField();
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
      Text('添加考试')
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
      this.FieldLabel('科目名称', true);
      TextInput({ placeholder: '如：高等数学、大学英语', text: $$this.examName })
        .width('100%')
        .height(52)
        .type(InputType.Normal)
        .placeholderColor(AppColors.TEXT_HINT)
        .fontSize(15)
        .fontColor(AppColors.TEXT_PRIMARY)
        .backgroundColor(AppColors.CARD)
        .borderRadius(AppSize.RADIUS_LG)
        .padding({ left: 16, right: 16 })
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
  }

  @Builder
  DateField() {
    Column() {
      this.FieldLabel('考试日期', true);
      Row() {
        Text(this.formatDate(this.examDate))
          .fontSize(15)
          .fontColor(AppColors.TEXT_PRIMARY)
          .layoutWeight(1)
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
  TimeRow() {
    Column({ space: 12 }) {
      this.FieldLabel('考试时间', true);
      Row({ space: 12 }) {
        Column({ space: 6 }) {
          Text('开始时间')
            .fontSize(12)
            .fontColor(AppColors.TEXT_SECONDARY)
            .padding({ left: 4 });

          Row() {
            Text(this.formatTime(this.startHour, this.startMinute))
              .fontSize(15)
              .fontColor(AppColors.TEXT_PRIMARY)
              .layoutWeight(1)
            Text('›')
              .fontSize(18)
              .fontColor(AppColors.TEXT_HINT)
          }
          .width('100%')
          .height(52)
          .padding({ left: 16, right: 16 })
          .backgroundColor(AppColors.CARD)
          .borderRadius(AppSize.RADIUS_LG)
          .onClick(() => this.startTimeDialogCtrl.open())
        }
        .layoutWeight(1)

        Column({ space: 6 }) {
          Text('结束时间')
            .fontSize(12)
            .fontColor(AppColors.TEXT_SECONDARY)
            .padding({ left: 4 });

          Row() {
            Text(this.formatTime(this.endHour, this.endMinute))
              .fontSize(15)
              .fontColor(AppColors.TEXT_PRIMARY)
              .layoutWeight(1)
            Text('›')
              .fontSize(18)
              .fontColor(AppColors.TEXT_HINT)
          }
          .width('100%')
          .height(52)
          .padding({ left: 16, right: 16 })
          .backgroundColor(AppColors.CARD)
          .borderRadius(AppSize.RADIUS_LG)
          .onClick(() => this.endTimeDialogCtrl.open())
        }
        .layoutWeight(1)
      }
      .width('100%')
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
  }

  @Builder
  LocationField() {
    Column() {
      this.FieldLabel('考场地点');
      Row() {
        Image($r('app.media.home_examlocation'))
          .width(25)
        TextInput({ placeholder: '如：综合楼5201、七号楼7201', text: $$this.location })
          .layoutWeight(1)
          .height(52)
          .type(InputType.Normal)
          .placeholderColor(AppColors.TEXT_HINT)
          .fontSize(15)
          .fontColor(AppColors.TEXT_PRIMARY)
          .backgroundColor(Color.Transparent)
          .borderRadius(0)
          .padding({ left: 8, right: 8 })
      }
      .width('100%')
      .height(52)
      .padding({ left: 16, right: 16 })
      .backgroundColor(AppColors.CARD)
      .borderRadius(AppSize.RADIUS_LG)
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
  }

  @Builder
  SaveButton() {
    Button(this.isSubmitting ? '保存中...' : '保存考试安排')
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
