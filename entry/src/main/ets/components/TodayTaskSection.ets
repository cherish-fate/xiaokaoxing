import { TaskModel, TodayTaskListModel } from '../model/TaskModel';
import { AppColors, AppSize } from '../utils/Constants';
import { RouteUrls } from '../utils/RouteUrls';
import { RouterUtil } from '../utils/RouterUtil';

@Component
export struct TodayTaskSection {
  @Prop taskList: TodayTaskListModel | null = null;
  onToggle: (id: number, completed: boolean) => void = () => {};

  build() {
    Column({ space: 12 }) {
      this.Header();
      if (this.taskList && this.taskList.hasTasks && this.taskList.list.length > 0) {
        this.TaskList();
      } else {
        this.EmptyHint();
      }
    }
    .width('100%')
    .padding({ left: 20, right: 20 })
  }

  @Builder
  Header() {
    Row({space:10}) {
      Image($r('app.media.home_todaytask'))
        .width(20)
        .fillColor('#ff607df7')
      Text('今日任务')
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor(AppColors.TEXT_PRIMARY)
      Blank()
      Row({ space: 4 }) {
        Text('+ 添加任务')
          .fontSize(14)
          .fontColor(AppColors.PRIMARY)
          .fontWeight(FontWeight.Medium)
      }
      .padding({ left: 8, right: 8, top: 4, bottom: 4 })
      .backgroundColor('#E8F0FF')
      .borderRadius(14)
      .onClick(() => {
        RouterUtil.push(RouteUrls.TASK_ADD);
      })
    }
    .width('100%')
  }

  @Builder
  EmptyHint() {
    Column({ space: 12 }) {
      Text(this.taskList?.emptyHint || '今日暂无任务，开始添加学习计划吧')
        .fontSize(14)
        .fontColor(AppColors.TEXT_SECONDARY)
    }
    .width('100%')
    .padding(20)
    .backgroundColor(AppColors.CARD)
    .borderRadius(AppSize.RADIUS_MD)
    .shadow({ radius: 6, color: 'rgba(0,0,0,0.04)', offsetY: 2 })
    .alignItems(HorizontalAlign.Center)
  }

  @Builder
  TaskList() {
    Column({ space: 10 }) {
      ForEach(this.taskList!.list, (item: TaskModel) => {
        this.TaskItem(item)
      }, (item: TaskModel) => `${item.id}_${item.isCompleted}`)
    }
  }

  @Builder
  TaskItem(item: TaskModel) {
    Row({ space: 12 }) {
      Checkbox()
        .select(item.isCompleted)
        .width(22)
        .height(22)
        .borderColor(AppColors.PRIMARY)
        .selectedColor(AppColors.PRIMARY)
        .onChange((checked: boolean) => {
          this.onToggle(item.id, checked);
        })

      Text(item.taskName)
        .fontSize(15)
        .fontColor(item.isCompleted ? AppColors.TEXT_HINT : AppColors.TEXT_PRIMARY)
        .fontWeight(item.isCompleted ? FontWeight.Normal : FontWeight.Medium)
        .decoration({ type: item.isCompleted ? TextDecorationType.LineThrough : TextDecorationType.None })
        .layoutWeight(1)
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
    }
    .width('100%')
    .padding(14)
    .backgroundColor(AppColors.CARD)
    .borderRadius(AppSize.RADIUS_MD)
    .shadow({ radius: 6, color: 'rgba(0,0,0,0.04)', offsetY: 2 })
    .onClick(() => {
      RouterUtil.pushWithParams(RouteUrls.TASK_DETAIL, { "task": item });
    })
  }
}
