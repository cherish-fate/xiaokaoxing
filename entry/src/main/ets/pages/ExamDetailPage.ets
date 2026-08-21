import { router, promptAction } from '@kit.ArkUI';
import { examRepository } from '../repository/ExamRepository';
import { AppColors, AppSize } from '../utils/Constants';
import { ToastUtil } from '../utils/ToastUtil';
import { Logger } from '../utils/Logger';
import { DateUtil } from '../utils/DateUtil';
import { UpdateExamRequest } from '../api/ApiService';

const TAG = 'ExamDetailPage';

@CustomDialog
struct DetailDatePickerDialog {
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
struct DetailTimePickerDialog {
  controller: CustomDialogController = new CustomDialogController({ builder: () => {} });
  title: string = '选择时间';
  @Link linkedHour: number;
  @Link linkedMinute: number;
  @State tempHour: number = 9;
  @State tempMinute: number = 0;
  @State tempDate: Date = new Date();

  aboutToAppear(): void {
    this.tempHour = this.linkedHour;
    this.tempMinute = this.linkedMinute;
    this.tempDate = new Date();
    this.tempDate.setHours(this.tempHour, this.tempMinute, 0, 0);
  }

  build() {
    Column() {
      Text(this.title)
        .fontSize(16)
        .fontWeight(FontWeight.Medium)
        .fontColor(AppColors.TEXT_PRIMARY)
        .margin({ top: 16, bottom: 8 })

      TimePicker({
        selected: this.tempDate
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
struct ExamDetailPage {
  @State examId: number = 0;
  @State examName: string = '';
  @State @Watch('onExamDateChange') examDate: Date = new Date();
  @State startHour: number = 9;
  @State startMinute: number = 0;
  @State endHour: number = 11;
  @State endMinute: number = 0;
  @State location: string = '';
  @State isCompleted: boolean = false;
  @State daysRemaining: number = 0;
  @State isSubmitting: boolean = false;
  @State isDeleting: boolean = false;
  @State isToggling: boolean = false;

  private dateDialogCtrl: CustomDialogController = new CustomDialogController({
    builder: DetailDatePickerDialog({
      linkedDate: $examDate
    }),
    alignment: DialogAlignment.Bottom,
    customStyle: true,
    autoCancel: true
  });

  private startTimeDialogCtrl: CustomDialogController = new CustomDialogController({
    builder: DetailTimePickerDialog({
      title: '选择开始时间',
      linkedHour: $startHour,
      linkedMinute: $startMinute
    }),
    alignment: DialogAlignment.Bottom,
    customStyle: true,
    autoCancel: true
  });

  private endTimeDialogCtrl: CustomDialogController = new CustomDialogController({
    builder: DetailTimePickerDialog({
      title: '选择结束时间',
      linkedHour: $endHour,
      linkedMinute: $endMinute
    }),
    alignment: DialogAlignment.Bottom,
    customStyle: true,
    autoCancel: true
  });

  aboutToAppear(): void {
    const params = router.getParams() as Record<string, Object>;
    if (params && params['exam']) {
      const exam = params['exam'] as Record<string, Object>;
      this.examId = exam['id'] as number;
      this.examName = exam['name'] as string;
      this.examDate = this.parseDate(exam['examDate'] as string);
      const startTimeArr = this.parseTime(exam['startTime'] as string);
      this.startHour = startTimeArr[0];
      this.startMinute = startTimeArr[1];
      const endTimeArr = this.parseTime(exam['endTime'] as string);
      this.endHour = endTimeArr[0];
      this.endMinute = endTimeArr[1];
      this.location = (exam['location'] as string) || '';
      this.isCompleted = exam['isCompleted'] as boolean;
      this.daysRemaining = exam['daysRemaining'] as number;
    }
  }

  private onExamDateChange(): void {
    this.daysRemaining = DateUtil.diffDays(DateUtil.format(this.examDate));
  }

  private parseDate(dateStr: string): Date {
    if (!dateStr) {
      return new Date();
    }
    const parts = dateStr.split('-');
    if (parts.length === 3) {
      return new Date(Number(parts[0]), Number(parts[1]) - 1, Number(parts[2]));
    }
    return new Date();
  }

  private parseTime(timeStr: string): [number, number] {
    if (!timeStr) {
      return [9, 0];
    }
    const parts = timeStr.split(':');
    if (parts.length === 2) {
      return [Number(parts[0]), Number(parts[1])];
    }
    return [9, 0];
  }

  private formatDate(d: Date): string {
    return DateUtil.format(d);
  }

  private formatTime(h: number, m: number): string {
    const hh = `${h}`.padStart(2, '0');
    const mm = `${m}`.padStart(2, '0');
    return `${hh}:${mm}`;
  }

  private timeRangeText(): string {
    return `${this.formatTime(this.startHour, this.startMinute)} - ${this.formatTime(this.endHour, this.endMinute)}`;
  }

  private countdownText(): string {
    if (this.daysRemaining < 0) {
      return '考试已过期';
    }
    if (this.daysRemaining === 0) {
      return '今天考试';
    }
    return `距考试还有 ${this.daysRemaining} 天`;
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

  private buildUpdateRequest(): UpdateExamRequest {
    return {
      name: this.examName.trim(),
      exam_date: this.formatDate(this.examDate),
      start_time: this.formatTime(this.startHour, this.startMinute),
      end_time: this.formatTime(this.endHour, this.endMinute),
      location: this.location && this.location.trim().length > 0 ? this.location.trim() : undefined,
      is_completed: this.isCompleted
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
      const req = this.buildUpdateRequest();
      const result = await examRepository.updateExam(this.examId, req);
      if (result.success && result.data) {
        ToastUtil.show('修改成功');
        setTimeout(() => {
          try { router.back(); } catch (_) {}
        }, 600);
      } else if (result.code === 401) {
        ToastUtil.show('登录已过期，请重新登录');
      } else if (result.code === 404) {
        ToastUtil.show('考试不存在或无权操作');
      } else if (result.code === 400) {
        ToastUtil.show(result.message || '提交内容不合法');
      } else {
        ToastUtil.show(result.message || '修改失败，请重试');
      }
    } catch (e) {
      Logger.error(TAG, 'handleSave failed', e as Error);
      ToastUtil.show('网络异常，请稍后重试');
    } finally {
      this.isSubmitting = false;
    }
  }

  private async handleToggleComplete(): Promise<void> {
    if (this.isToggling) {
      return;
    }
    this.isToggling = true;
    const newValue = !this.isCompleted;
    this.isCompleted = newValue;
    try {
      const toggleReq: UpdateExamRequest = { is_completed: newValue };
      const result = await examRepository.updateExam(this.examId, toggleReq);
      if (!result.success) {
        this.isCompleted = !newValue;
        if (result.code === 401) {
          ToastUtil.show('登录已过期，请重新登录');
        } else {
          ToastUtil.show(result.message || '更新失败');
        }
      }
    } catch (e) {
      this.isCompleted = !newValue;
      Logger.error(TAG, 'handleToggleComplete failed', e as Error);
      ToastUtil.show('网络异常，请稍后重试');
    } finally {
      this.isToggling = false;
    }
  }

  private async handleDelete(): Promise<void> {
    if (this.isDeleting) {
      return;
    }
    const confirmed = await this.showDeleteConfirm();
    if (!confirmed) {
      return;
    }
    this.isDeleting = true;
    try {
      const result = await examRepository.deleteExam(this.examId);
      if (result.success) {
        ToastUtil.show('删除成功');
        setTimeout(() => {
          try { router.back(); } catch (_) {}
        }, 600);
      } else if (result.code === 401) {
        ToastUtil.show('登录已过期，请重新登录');
      } else if (result.code === 404) {
        ToastUtil.show('考试不存在或无权操作');
      } else {
        ToastUtil.show(result.message || '删除失败，请重试');
      }
    } catch (e) {
      Logger.error(TAG, 'handleDelete failed', e as Error);
      ToastUtil.show('网络异常，请稍后重试');
    } finally {
      this.isDeleting = false;
    }
  }

  private showDeleteConfirm(): Promise<boolean> {
    return new Promise((resolve: (v: boolean) => void) => {
      promptAction.showDialog({
        message: '确定删除该考试吗？删除后不可恢复。',
        buttons: [
          { text: '取消', color: '#666666' },
          { text: '删除', color: AppColors.DANGER }
        ]
      }).then((result: promptAction.ShowDialogSuccessResponse) => {
        resolve(result.index === 1);
      }).catch(() => {
        resolve(false);
      });
    });
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
        Column({ space: 16 }) {
          this.StatusCard();
          this.CompleteToggle();
          this.FormCard();
          this.ActionArea();
        }
        .width('100%')
        .padding({ left: 20, right: 20, top: 4, bottom: 40 })
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
      Image($r('app.media.examDetail_back'))
        .width(40)
        .height(40)
        .padding(10)
        .backgroundColor(AppColors.CARD)
        .borderRadius(20)
        .onClick(() => this.handleClose())

      Text('考试详情')
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor(AppColors.TEXT_PRIMARY)
        .layoutWeight(1)
        .textAlign(TextAlign.Center)
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })

      Row()
        .width(40)
        .height(40)
    }
    .width('100%')
    .padding({ left: 20, right: 20, top: 12, bottom: 12 })
    .alignItems(VerticalAlign.Center)
  }

  @Builder
  StatusCard() {
    Column() {
      if (this.isCompleted) {
        Column({ space: 8 }) {
          Row() {
            Column({ space: 4 }) {
              Text('考试已完成')
                .fontSize(14)
                .fontColor('rgba(255,255,255,0.9)')
              Text(this.examName)
                .fontSize(18)
                .fontWeight(FontWeight.Bold)
                .fontColor(Color.White)
            }
            .alignItems(HorizontalAlign.Start)

            Blank()

            Text('已完成')
              .fontSize(12)
              .fontWeight(FontWeight.Medium)
              .fontColor(Color.White)
              .padding({ left: 10, right: 10, top: 4, bottom: 4 })
              .backgroundColor('rgba(255,255,255,0.3)')
              .borderRadius(10)
          }
          .width('100%')
          .alignItems(VerticalAlign.Top)

          Row({ space: 16 }) {

              Text(this.formatDate(this.examDate))
                .fontSize(12)
                .fontColor('rgba(255,255,255,0.85)')


              Text(this.timeRangeText())
                .fontSize(12)
                .fontColor('rgba(255,255,255,0.85)')

          }
          .margin({ top: 4 })
        }
        .width('100%')
        .padding(18)
        .linearGradient({
          direction: GradientDirection.RightBottom,
          colors: [['#D8DCE2', 0], ['#C5CAD2', 1]]
        })
        .borderRadius(AppSize.RADIUS_LG)
        .shadow({ radius: 8, color: 'rgba(0,0,0,0.08)', offsetY: 4 })
      } else {
        Column({ space: 8 }) {
          Row() {
            Column({ space: 6 }) {
              Text(this.countdownText())
                .fontSize(13)
                .fontColor('rgba(255,255,255,0.85)')
              Row({ space: 4 }) {
                if (this.daysRemaining > 0) {
                  Text(`${this.daysRemaining}`)
                    .fontSize(42)
                    .fontWeight(FontWeight.Bold)
                    .fontColor(Color.White)
                    .lineHeight(50)
                  Text('天')
                    .fontSize(18)
                    .fontColor(Color.White)
                    .margin({ top: 16 })
                }
              }
              Text(this.examName)
                .fontSize(16)
                .fontWeight(FontWeight.Medium)
                .fontColor(Color.White)
            }
            .alignItems(HorizontalAlign.Start)

            Blank()

            Text(this.daysRemaining < 0 ? '已过期' : '待考')
              .fontSize(12)
              .fontWeight(FontWeight.Medium)
              .fontColor(Color.White)
              .padding({ left: 10, right: 10, top: 4, bottom: 4 })
              .backgroundColor('rgba(255,255,255,0.25)')
              .borderRadius(10)
          }
          .width('100%')
          .alignItems(VerticalAlign.Top)

          Row({ space: 16 }) {

              Text(this.formatDate(this.examDate))
                .fontSize(12)
                .fontColor('rgba(255,255,255,0.85)')

              Text(this.timeRangeText())
                .fontSize(12)
                .fontColor('rgba(255,255,255,0.85)')

          }
          .margin({ top: 8 })
          .padding({ top: 10 })
          .border({ width: { top: 1 }, color: 'rgba(255,255,255,0.2)' })
        }
        .width('100%')
        .padding(18)
        .linearGradient({
          direction: GradientDirection.RightBottom,
          colors: [['#5B8BFF', 0], ['#4A7FFF', 1]]
        })
        .borderRadius(AppSize.RADIUS_LG)
        .shadow({ radius: 12, color: 'rgba(74,127,255,0.25)', offsetY: 6 })
      }
    }
    .width('100%')
  }

  @Builder
  CompleteToggle() {
    Row() {
      Column({ space: 2 }) {
        Text(this.isCompleted ? '✓ 已完成' : '标记为已完成')
          .fontSize(15)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.isCompleted ? AppColors.SUCCESS : AppColors.TEXT_PRIMARY)
        Text(this.isCompleted ? '考试已标记为完成状态' : '考试结束后可手动标记完成')
          .fontSize(12)
          .fontColor(AppColors.TEXT_HINT)
      }
      .alignItems(HorizontalAlign.Start)

      Blank()

      Toggle({ type: ToggleType.Switch, isOn: this.isCompleted })
        .selectedColor(this.isCompleted ? AppColors.SUCCESS : AppColors.PRIMARY)
        .onChange((isOn: boolean) => {
          this.handleToggleComplete();
        })
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 14, bottom: 14 })
    .backgroundColor(AppColors.CARD)
    .borderRadius(AppSize.RADIUS_LG)
    .shadow({ radius: 4, color: 'rgba(0,0,0,0.04)', offsetY: 2 })
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
  FormCard() {
    Column({ space: 16 }) {
      Text('考试信息')
        .fontSize(14)
        .fontWeight(FontWeight.Bold)
        .fontColor(AppColors.TEXT_PRIMARY)

      // 科目名称
      Column() {
        this.FieldLabel('科目名称', true);
        TextInput({ placeholder: '如：高等数学、大学英语', text: $$this.examName })
          .width('100%')
          .height(52)
          .type(InputType.Normal)
          .placeholderColor(AppColors.TEXT_HINT)
          .fontSize(15)
          .fontColor(AppColors.TEXT_PRIMARY)
          .backgroundColor(AppColors.BG)
          .borderRadius(AppSize.RADIUS_MD)
          .padding({ left: 16, right: 16 })
      }
      .width('100%')
      .alignItems(HorizontalAlign.Start)

      // 考试日期
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
        .backgroundColor(AppColors.BG)
        .borderRadius(AppSize.RADIUS_MD)
        .onClick(() => this.dateDialogCtrl.open())
      }
      .width('100%')
      .alignItems(HorizontalAlign.Start)

      // 考试时间
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
            .backgroundColor(AppColors.BG)
            .borderRadius(AppSize.RADIUS_MD)
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
            .backgroundColor(AppColors.BG)
            .borderRadius(AppSize.RADIUS_MD)
            .onClick(() => this.endTimeDialogCtrl.open())
          }
          .layoutWeight(1)
        }
        .width('100%')
      }
      .width('100%')
      .alignItems(HorizontalAlign.Start)

      // 考场地点
      Column() {
        this.FieldLabel('考场地点');
        Row() {
          Image($r('app.media.home_examlocation'))
            .width(20)
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
        .backgroundColor(AppColors.BG)
        .borderRadius(AppSize.RADIUS_MD)
      }
      .width('100%')
      .alignItems(HorizontalAlign.Start)
    }
    .width('100%')
    .padding(16)
    .backgroundColor(AppColors.CARD)
    .borderRadius(AppSize.RADIUS_LG)
    .shadow({ radius: 4, color: 'rgba(0,0,0,0.04)', offsetY: 2 })
  }

  @Builder
  ActionArea() {
    Column({ space: 10 }) {
      Button(this.isSubmitting ? '保存中...' : '保存修改')
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
        .onClick(() => this.handleSave())

      Button(this.isDeleting ? '删除中...' : '删除考试')
        .width('100%')
        .height(44)
        .backgroundColor(Color.Transparent)
        .fontSize(14)
        .fontWeight(FontWeight.Medium)
        .fontColor(AppColors.DANGER)
        .enabled(!this.isDeleting)
        .onClick(() => this.handleDelete())
    }
    .width('100%')
    .margin({ top: 4 })
  }
}
