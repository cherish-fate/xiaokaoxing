import { router, promptAction } from '@kit.ArkUI';
import { taskRepository } from '../repository/TaskRepository';
import { AppColors, AppSize } from '../utils/Constants';
import { ToastUtil } from '../utils/ToastUtil';
import { Logger } from '../utils/Logger';
import { DateUtil } from '../utils/DateUtil';
import { UpdateTaskRequest } from '../api/ApiService';

const TAG = 'TaskDetailPage';
const MAX_LENGTH = 200;

@CustomDialog
struct TaskDatePickerDialog {
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
struct TaskDetailPage {
  @State taskId: number = 0;
  @State taskName: string = '';
  @State planDate: Date = new Date();
  @State isCompleted: boolean = false;
  @State isSubmitting: boolean = false;
  @State isDeleting: boolean = false;
  @State isToggling: boolean = false;

  private dateDialogCtrl: CustomDialogController = new CustomDialogController({
    builder: TaskDatePickerDialog({
      linkedDate: $planDate
    }),
    alignment: DialogAlignment.Bottom,
    customStyle: true,
    autoCancel: true
  });

  aboutToAppear(): void {
    const params = router.getParams() as Record<string, Object>;
    if (params && params['task']) {
      const task = params['task'] as Record<string, Object>;
      this.taskId = task['id'] as number;
      this.taskName = task['taskName'] as string;
      this.planDate = this.parseDate(task['planDate'] as string);
      this.isCompleted = task['isCompleted'] as boolean;
    }
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

  private formatDate(d: Date): string {
    return DateUtil.format(d);
  }

  private isToday(d: Date): boolean {
    const today = new Date();
    return d.getFullYear() === today.getFullYear() &&
      d.getMonth() === today.getMonth() &&
      d.getDate() === today.getDate();
  }

  private dateLabel(): string {
    return this.isToday(this.planDate) ? `${this.formatDate(this.planDate)}（今天）` : this.formatDate(this.planDate);
  }

  private validate(): string | null {
    if (!this.taskName || this.taskName.trim().length === 0) {
      return '请输入任务名称';
    }
    return null;
  }

  private buildUpdateRequest(): UpdateTaskRequest {
    const req: UpdateTaskRequest = {
      task_name: this.taskName.trim(),
      plan_date: this.formatDate(this.planDate),
      is_completed: this.isCompleted
    };
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
      const req = this.buildUpdateRequest();
      const result = await taskRepository.updateTask(this.taskId, req);
      if (result.success && result.data) {
        ToastUtil.show('修改成功');
        setTimeout(() => {
          try { router.back(); } catch (_) {}
        }, 600);
      } else if (result.code === 401) {
        ToastUtil.show('登录已过期，请重新登录');
      } else if (result.code === 404) {
        ToastUtil.show('任务不存在或无权操作');
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
      const toggleReq: UpdateTaskRequest = { is_completed: newValue };
      const result = await taskRepository.updateTask(this.taskId, toggleReq);
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
      const result = await taskRepository.deleteTask(this.taskId);
      if (result.success) {
        ToastUtil.show('删除成功');
        setTimeout(() => {
          try { router.back(); } catch (_) {}
        }, 600);
      } else if (result.code === 401) {
        ToastUtil.show('登录已过期，请重新登录');
      } else if (result.code === 404) {
        ToastUtil.show('任务不存在或无权操作');
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
        message: '确定删除该任务吗？删除后不可恢复。',
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
    Stack({ alignContent: Alignment.Center }) {
      Row() {
        Image($r('app.media.examDetail_back'))
          .width(40)
          .height(40)
          .padding(10)
          .backgroundColor(AppColors.CARD)
          .borderRadius(20)
          .onClick(() => this.handleClose())
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)

      Text('任务详情')
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor(AppColors.TEXT_PRIMARY)
    }
    .width('100%')
    .padding({ left: 20, right: 20, top: 12, bottom: 12 })
  }

  @Builder
  StatusCard() {
    Column() {
      if (this.isCompleted) {
        Column({ space: 8 }) {
          Row() {
            Column({ space: 4 }) {
              Text(this.taskName)
                .fontSize(18)
                .fontWeight(FontWeight.Bold)
                .fontColor(Color.White)
                .maxLines(2)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
            }
            .alignItems(HorizontalAlign.Start)
            .layoutWeight(1)

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

          Row({ space: 8 }) {
            Text(this.dateLabel())
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
            Column({ space: 4 }) {
              Text(this.taskName)
                .fontSize(18)
                .fontWeight(FontWeight.Bold)
                .fontColor(Color.White)
                .maxLines(2)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
            }
            .alignItems(HorizontalAlign.Start)
            .layoutWeight(1)

            Text('待办')
              .fontSize(12)
              .fontWeight(FontWeight.Medium)
              .fontColor(Color.White)
              .padding({ left: 10, right: 10, top: 4, bottom: 4 })
              .backgroundColor('rgba(255,255,255,0.25)')
              .borderRadius(10)
          }
          .width('100%')
          .alignItems(VerticalAlign.Top)

          Row({ space: 8 }) {
            Text(this.dateLabel())
              .fontSize(12)
              .fontColor('rgba(255,255,255,0.85)')
          }
          .margin({ top: 4 })
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
        Text(this.isCompleted ? '任务已完成' : '完成后可手动标记')
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
      Text('任务信息')
        .fontSize(14)
        .fontWeight(FontWeight.Bold)
        .fontColor(AppColors.TEXT_PRIMARY)

      // 任务名称
      Column() {
        this.FieldLabel('任务名称', true);
        Stack({ alignContent: Alignment.BottomEnd }) {
          TextInput({ placeholder: '如：复习高等数学第三章', text: $$this.taskName })
            .width('100%')
            .height(52)
            .type(InputType.Normal)
            .maxLength(MAX_LENGTH)
            .placeholderColor(AppColors.TEXT_HINT)
            .fontSize(15)
            .fontColor(AppColors.TEXT_PRIMARY)
            .backgroundColor(AppColors.BG)
            .borderRadius(AppSize.RADIUS_MD)
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

      // 计划日期
      Column() {
        this.FieldLabel('计划日期');
        Row() {
          Image($r('app.media.home_examclock'))
            .width(20)
            .fillColor('#ffd3d3d3')
          Text(this.dateLabel())
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
        .backgroundColor(AppColors.BG)
        .borderRadius(AppSize.RADIUS_MD)
        .onClick(() => this.dateDialogCtrl.open())
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

      Button(this.isDeleting ? '删除中...' : '删除任务')
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
