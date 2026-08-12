import { AppColors, AppSize } from '../utils/Constants';
import { CheckinStatsModel } from '../model/CommunityHomeModel';
import { TodayCheckinModel } from '../model/CheckinModel';
import { RouterUtil } from '../utils/RouterUtil';
import { RouteUrls } from '../utils/RouteUrls';

interface WeekDay {
  label: string;
  date: number;
  isToday: boolean;
}

@Component
export struct CheckinCard {
  @Link checkinStats: CheckinStatsModel;
  @Link todayModel: TodayCheckinModel;

  private getWeekDays(): WeekDay[] {
    const days: string[] = ['一', '二', '三', '四', '五', '六', '日'];
    const now: Date = new Date();
    const dayOfWeek: number = now.getDay() === 0 ? 6 : now.getDay() - 1;
    const result: WeekDay[] = [];
    for (let i: number = 0; i < 7; i++) {
      const d: Date = new Date(now);
      d.setDate(now.getDate() - dayOfWeek + i);
      result.push({
        label: days[i],
        date: d.getDate(),
        isToday: i === dayOfWeek
      });
    }
    return result;
  }

  build() {
    Column({ space: 16 }) {
      Row() {
        Row({ space: 4 }) {
          Text('🔥')
            .fontSize(18)
          Text('我的打卡')
            .fontSize(17)
            .fontWeight(FontWeight.Medium)
            .fontColor(AppColors.TEXT_PRIMARY)
        }
        .layoutWeight(1)

        Row({ space: 2 }) {
          Text('查看排行')
            .fontSize(13)
            .fontColor(AppColors.PRIMARY)
          Text('>')
            .fontSize(13)
            .fontColor(AppColors.PRIMARY)
        }
        .onClick(() => RouterUtil.push(RouteUrls.COMMUNITY_CHECKIN))
      }
      .width('100%')

      Row({space:10}) {
        this.StatBlock(`${this.checkinStats.totalDays}`, '累计打卡')
        this.StatBlock(`${this.checkinStats.continuousDays}`, '连续天数')
        this.StatBlock(`#${this.checkinStats.rank || '--'}`, '本校排名')
      }
      .width('100%')

      Row() {
        ForEach(this.getWeekDays(), (day: WeekDay) => {
          Column({ space: 6 }){
            Text(day.label)
              .fontSize(12)
              .fontColor(AppColors.TEXT_HINT)
            Column() {
              Text(`${day.date}`)
                .fontSize(15)
                .fontWeight(day.isToday ? FontWeight.Bold : FontWeight.Medium)
                .fontColor(day.isToday ? Color.White : AppColors.TEXT_SECONDARY)
            }
            .height(40)
            .width(40)
            .borderRadius(10)
            .justifyContent(FlexAlign.Center)
            .backgroundColor(day.isToday ? AppColors.PRIMARY : Color.Transparent)
          }
          .justifyContent(FlexAlign.Center)

        })
      }
      .width('100%')

      Button() {
        Row({ space: 6 }) {
          Text(this.todayModel.hasCheckedIn ? '今日已打卡，继续加油' : '今日去打卡')
            .fontSize(15)
            .fontWeight(FontWeight.Medium)
            .fontColor(Color.White)
        }
      }
      .width('100%')
      .height(48)
      .backgroundColor(AppColors.PRIMARY)
      .borderRadius(24)
      .onClick(() => RouterUtil.push(RouteUrls.COMMUNITY_CHECKIN))
    }
    .width('100%')
    .padding(AppSize.PADDING_LG)
    .backgroundColor(Color.White)
    .borderRadius(AppSize.RADIUS_LG)
  }

  @Builder
  StatBlock(value: string, label: string) {
    Column({ space: 4 }) {
      Text(value)
        .fontSize(26)
        .fontWeight(FontWeight.Bold)
        .fontColor(AppColors.PRIMARY)
      Text(label)
        .fontSize(12)
        .fontColor(AppColors.TEXT_HINT)
    }
    .width(50)
    .padding({top:5,bottom:5})
    .borderRadius(15)
    .backgroundColor("#fff6f7fa")
    .layoutWeight(1)
    .alignItems(HorizontalAlign.Center)
  }
}
