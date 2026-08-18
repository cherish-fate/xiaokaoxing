import { ExamCountdownModel, TodayProgressModel } from '../model/ExamModel';
import { AppColors, AppSize } from '../utils/Constants';
import { RouteUrls } from '../utils/RouteUrls';
import { RouterUtil } from '../utils/RouterUtil';

@Component
export struct CountdownCard {
  @Prop countdown: ExamCountdownModel | null = null;
  @Prop progress: TodayProgressModel = new TodayProgressModel(0, 0, 0);
  onAddExam: () => void = () => {};

  build() {
    Column({ space: 16 }) {
      if (this.countdown && this.countdown.hasExam) {
        this.ExamInfoArea();
        this.Divider();
        this.ProgressArea();
      } else {
        this.EmptyArea();
      }
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

  @Builder
  ExamInfoArea() {
    Row() {
      Column({ space: 8 }) {
        Text('最近考试倒计时')
          .fontSize(13)
          .fontColor('rgba(255,255,255,0.8)')
        Row({ space: 4 }) {
          Text(`${this.countdown!.countdownDays}`)
            .fontSize(48)
            .fontWeight(FontWeight.Bold)
            .fontColor(Color.White)
            .lineHeight(56)
          Text('天')
            .fontSize(20)
            .fontColor(Color.White)
            .margin({ top: 20 })
        }
        Text(this.countdown!.examName)
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .fontColor(Color.White)
        Text(`${this.countdown!.examDate} ${this.countdown!.timeRangeText()}`)
          .fontSize(12)
          .fontColor('rgba(255,255,255,0.85)')
      }
      .alignItems(HorizontalAlign.Start)

      Blank()

      this.ProgressRing()
    }
    .alignItems(VerticalAlign.Top)
    .width('100%')
  }

  @Builder
  ProgressRing() {
    Stack({ alignContent: Alignment.Center }) {
      Progress({ value: this.progress.progressPercentage, total: 100, type: ProgressType.Ring })
        .width(90)
        .height(90)
        .color('#FFFFFF')
      Column() {
        Text(`${this.progress.progressPercentage}%`)
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor(Color.White)
        Text('考试进度')
          .fontSize(11)
          .fontColor('rgba(255,255,255,0.85)')
      }
    }
  }

  @Builder
  Divider() {
    Row() {
      Text('')
    }
    .width('100%')
    .height(1)
    .backgroundColor('rgba(255,255,255,0.2)')
  }

  @Builder
  ProgressArea() {
    Row() {
      this.ProgressStat('已完成', `${this.progress.completed}`)
      this.ProgressStat('待完成', `${Math.max(0, this.progress.total - this.progress.completed)}`)
      this.ProgressStat('门考试', `${this.progress.total}`)
    }
    .width('100%')
    .justifyContent(FlexAlign.SpaceBetween)
  }

  @Builder
  ProgressStat(label: string, value: string) {
    Column({ space: 4 }) {
      Text(value)
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .fontColor(Color.White)
      Text(label)
        .fontSize(12)
        .fontColor('rgba(255,255,255,0.85)')
    }
    .layoutWeight(1)
    .alignItems(HorizontalAlign.Center)
  }

  @Builder
  EmptyArea() {
    Column({ space: 12 }) {
      Text('📝')
        .fontSize(40)
      Text('暂无考试，请添加')
        .fontSize(15)
        .fontColor(Color.White)
    }
    .width('100%')
    .alignItems(HorizontalAlign.Center)
    .padding({ top: 16, bottom: 8 })
  }
}
