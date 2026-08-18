import { ExamModel } from '../model/ExamModel';
import { AppColors, AppSize } from '../utils/Constants';
import { RouteUrls } from '../utils/RouteUrls';
import { RouterUtil } from '../utils/RouterUtil';

@Component
export struct ExamScheduleSection {
  @Prop exams: ExamModel[] = [];
  @Prop completedCount: number = 0;
  @Prop pendingCount: number = 0;
  onDelete: (id: number) => void = () => {};

  build() {
    Column({ space: 12 }) {
      this.Header();

      if (this.exams.length === 0) {
        this.EmptyHint();
      } else {
        Scroll() {
          Column({ space: 10 }) {
            ForEach(this.exams, (item: ExamModel) => {
              this.ExamItemView(item)
            }, (item: ExamModel) => `${item.id}`)
          }
        }
        .scrollBar(BarState.Off)
        .edgeEffect(EdgeEffect.Spring)
        .height(236)
      }
    }
    .width('100%')
    .padding({ left: 20, right: 20 })
  }

  @Builder
  Header() {
    Row() {
      Text('考试时间表')
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor(AppColors.TEXT_PRIMARY)
      Blank()
      Row({ space: 4 }) {
        Text('+ 添加考试')
          .fontSize(14)
          .fontColor(AppColors.PRIMARY)
          .fontWeight(FontWeight.Medium)
      }
      .padding({ left: 12, right: 12, top: 6, bottom: 6 })
      .backgroundColor('#E8F0FF')
      .borderRadius(14)
      .onClick(() => {
        RouterUtil.push(RouteUrls.EXAM_ADD);
      })
    }
    .width('100%')
  }

  @Builder
  EmptyHint() {
    Row() {
      Text('暂无考试')
        .fontSize(14)
        .fontColor(AppColors.TEXT_HINT)

    }
    .width('100%')
    .padding(20)
    .backgroundColor(AppColors.CARD)
    .borderRadius(AppSize.RADIUS_MD)
    .justifyContent(FlexAlign.Center)
    .shadow({ radius: 6, color: 'rgba(0,0,0,0.04)', offsetY: 2 })
  }

  @Builder
  ExamItemView(item: ExamModel) {
    Row() {
      Column({ space: 6 }) {
        Row({ space: 8 }) {
          Row({ space: 6 }) {
            Circle()
              .width(8)
              .height(8)
              .fill(item.isCompleted ? AppColors.SUCCESS : AppColors.PRIMARY)
            Text(item.name)
              .fontSize(16)
              .fontWeight(FontWeight.Medium)
              .fontColor(item.isCompleted ? AppColors.TEXT_HINT : AppColors.TEXT_PRIMARY)
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
              .decoration({ type: item.isCompleted ? TextDecorationType.LineThrough : TextDecorationType.None })
          }
          Blank()
          if (item.isCompleted) {
            Text('✓ 已完成')
              .fontSize(12)
              .fontColor(AppColors.SUCCESS)
              .fontWeight(FontWeight.Medium)
              .padding({ left: 8, right: 8, top: 3, bottom: 3 })
              .backgroundColor('#E6F7F5')
              .borderRadius(10)
          } else {
            Text(item.daysText)
              .fontSize(12)
              .fontColor(item.isExpired() ? AppColors.EXPIRED : AppColors.PRIMARY)
              .fontWeight(FontWeight.Medium)
              .padding({ left: 8, right: 8, top: 3, bottom: 3 })
              .backgroundColor(item.isExpired() ? '#F0F0F0' : '#E8F0FF')
              .borderRadius(10)
          }
        }

        Row({ space: 12 }) {
          Row({ space: 4 }) {
            Image($r('app.media.home_examclock'))
              .width(15)
              .fillColor('#ffd3d3d3')
            Text(`${item.examDate} ${item.startTime}`)
              .fontSize(12)
              .fontColor(AppColors.TEXT_SECONDARY)
          }
          if (item.hasLocation()) {
            Row({ space: 4 }) {
              Image($r('app.media.home_examlocation'))
                .width(15)
              Text(item.location)
                .fontSize(12)
                .fontColor(AppColors.TEXT_SECONDARY)
            }
          }
        }
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)
    }
    .width('100%')
    .padding(14)
    .backgroundColor(AppColors.CARD)
    .borderRadius(AppSize.RADIUS_MD)
    .shadow({ radius: 6, color: 'rgba(0,0,0,0.04)', offsetY: 2 })
    .onClick(() => {
      RouterUtil.pushWithParams(RouteUrls.EXAM_DETAIL, { "exam": item });
    })
  }
}
