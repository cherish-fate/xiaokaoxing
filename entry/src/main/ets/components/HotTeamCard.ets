import { AppColors, AppSize } from '../utils/Constants';
import { HotTeamModel } from '../model/CommunityHomeModel';
import { RouterUtil } from '../utils/RouterUtil';
import { RouteUrls } from '../utils/RouteUrls';
import { ToastUtil } from '../utils/ToastUtil';
import { teamRepository } from '../repository/TeamRepository';

@Component
export struct HotTeamCard {
  @Link hotTeams: HotTeamModel[];
  @State joiningTeamId: number = 0;

  private async onJoinTeam(team: HotTeamModel): Promise<void> {
    if (this.joiningTeamId === team.id) return;
    this.joiningTeamId = team.id;
    const res = await teamRepository.joinTeam(team.id);
    this.joiningTeamId = 0;
    if (!res.success) {
      ToastUtil.show(res.message || '申请失败');
      return;
    }
    ToastUtil.show(res.message || '申请成功，等待队长审核');
    // 乐观更新：将 joinStatus 设置为"待审核"，立即反映在 UI 上
    this.hotTeams = this.hotTeams.map((t: HotTeamModel) => {
      if (t.id === team.id) {
        return new HotTeamModel(
          t.id, t.name, t.subject, t.memberCount, t.maxMembers, t.checkinRate,
          t.totalCheckins, t.onlineCount, t.isCreator, '待审核', t.pendingRequests,
          t.description, t.resourceCount
        );
      }
      return t;
    });
  }

  @Builder
  TeamItem(team: HotTeamModel) {
    Column({ space: 14 }) {
      Row() {
        Column() {
          Image(team.subject === '高等数学' ? $r('app.media.community_math') :
            team.subject === '大学英语' ? $r('app.media.community_english') :
            team.subject === '线性代数' ? $r('app.media.community_xiandai') :
            team.subject === '数据结构' ? $r('app.media.community_data') : $r('app.media.community_teamicon'))
            .width(22)
        }
        .width(48)
        .height(48)
        .backgroundColor('#E8F0FF')
        .borderRadius(12)
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)

        Column({ space: 4 }) {
          Row({ space: 6 }) {
            Text(team.name)
              .fontSize(15)
              .fontWeight(FontWeight.Medium)
              .fontColor(AppColors.TEXT_PRIMARY)
          }
          Row({space:5}){
            Text(team.subject)
              .fontSize(11)
              .fontColor(AppColors.PRIMARY)
              .backgroundColor('#E8F0FF')
              .padding({ left: 8, right: 8, top: 2, bottom: 2 })
              .borderRadius(10)
            Row({ space: 3 }) {
              Circle()
                .width(6)
                .height(6)
                .fill(AppColors.SUCCESS)
              Text(`${team.onlineCount}人在线`)
                .fontSize(11)
                .fontColor(AppColors.SUCCESS)
            }
          }
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)
        .margin({ left: 12 })
      }
      .width('100%')
       Divider()
      Row() {
        this.TeamStat(`${team.memberCount}/${team.maxMembers}`, '成员', '#ff1c1c1c')
        this.TeamStat(`${team.checkinRate.toFixed(0)}%`, '打卡率', '#ff70ccc8')
        this.TeamStat(`${team.totalCheckins}`, '总打卡', '#ffeb8734')
      }
      .width('100%')

      if (team.isCreator) {
        // 自己创建的小队：显示"管理小队"按钮，跳转详情页
        Button('管理小队')
          .width('100%')
          .height(40)
          .backgroundColor('#F0F4FF')
          .fontSize(14)
          .fontColor(AppColors.PRIMARY)
          .borderRadius(10)
          .onClick(() => RouterUtil.push(RouteUrls.COMMUNITY_TEAM_DETAIL))
      } else if (team.isMember) {
        // 已加入的小队：显示"已加入"标签
        Row({ space: 6 }) {
          Text('✓ 已加入')
            .fontSize(13)
            .fontColor(AppColors.SUCCESS)
        }
        .justifyContent(FlexAlign.Center)
        .borderRadius(15)
        .backgroundColor('#E6F7F5')
        .width('100%')
        .padding({ top: 10, bottom: 10 })
      } else if (team.joinStatus === '待审核') {
        // 已申请待审核：显示"审核中"标签
        Row({ space: 6 }) {
          Image($r('app.media.community_shalou'))
            .width(20)
          Text('审核中')
            .fontSize(13)
            .fontColor(AppColors.TEXT_SECONDARY)
        }
        .justifyContent(FlexAlign.Center)
        .borderRadius(15)
        .backgroundColor('#ffe7e6e6')
        .width('100%')
        .padding({ top: 10, bottom: 10 })
      } else {
        // 别人创建的小队：显示"申请加入"按钮，点击后立即发起申请
        Button(this.joiningTeamId === team.id ? '申请中...' : '申请加入（需审核）')
          .width('100%')
          .height(40)
          .backgroundColor(AppColors.PRIMARY)
          .fontSize(14)
          .fontColor(Color.White)
          .borderRadius(10)
          .enabled(this.joiningTeamId !== team.id)
          .onClick(() => this.onJoinTeam(team))
      }
    }
    .width('100%')
    .padding(AppSize.PADDING_LG)
    .backgroundColor('#FAFBFD')
    .borderRadius(AppSize.RADIUS_MD)
    .onClick(() => RouterUtil.push(RouteUrls.COMMUNITY_TEAM_DETAIL))
  }

  @Builder
  TeamStat(value: string, label: string,color:string) {
    Column({ space: 4 }) {
      Text(value)
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .fontColor(color)
      Text(label)
        .fontSize(12)
        .fontColor(AppColors.TEXT_HINT)
    }
    .layoutWeight(1)
    .alignItems(HorizontalAlign.Center)
  }

  build() {
    Column() {
      Row() {
        Row({ space: 4 }) {
          Image($r('app.media.community_team'))
            .width(20)
          Text('热门备考小队')
            .fontSize(17)
            .fontWeight(FontWeight.Medium)
            .fontColor(AppColors.TEXT_PRIMARY)
        }
        .layoutWeight(1)

        Row({ space: 2 }) {
          Text('创建')
            .fontSize(13)
            .fontColor(AppColors.PRIMARY)
          Text('>')
            .fontSize(13)
            .fontColor(AppColors.PRIMARY)
        }
        .onClick(() => RouterUtil.push(RouteUrls.COMMUNITY_TEAM))
      }
      .width('100%')
      .margin({ bottom: 12 })

      Column({ space: 12 }) {
        if (this.hotTeams.length === 0) {
          Column({ space: 6 }) {
            Text('暂无小队')
              .fontSize(14)
              .fontColor(AppColors.TEXT_HINT)
            Text('去创建第一个小队吧')
              .fontSize(12)
              .fontColor(AppColors.TEXT_HINT)
          }
          .width('100%')
          .padding({ top: 24, bottom: 24 })
        } else {
          ForEach(this.hotTeams, (team: HotTeamModel) => {
            this.TeamItem(team)
          }, (team: HotTeamModel) => `${team.id}_${team.isCreator}_${team.joinStatus}`)
        }
      }
      .width('100%')
    }
    .width('100%')
    .padding(AppSize.PADDING_LG)
    .backgroundColor(Color.White)
    .borderRadius(AppSize.RADIUS_LG)
  }
}
