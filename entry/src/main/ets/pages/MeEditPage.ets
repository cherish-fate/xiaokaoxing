import { promptAction } from '@kit.ArkUI';
import { AppColors } from '../utils/Constants';
import { ToastUtil } from '../utils/ToastUtil';
import { LoadingView, ErrorView } from '../components/StateViews';
import { RouterUtil } from '../utils/RouterUtil';
import { MeUserProfileModel } from '../model/MeModel';
import { MeEditFormModel } from '../model/MeEditModel';
import { meRepository } from '../repository/MeRepository';
import { apiService, Major } from '../api/ApiService';

interface MajorSelectorResult {
  index: number;
  value: string;
  majorId: number;
}

function defaultOnConfirm(result: MajorSelectorResult): void {}

@CustomDialog
struct MajorSelectorDialog {
  controller: CustomDialogController = new CustomDialogController({
    builder: () => {}
  });
  @Link majors: Major[];
  initialIndex: number = 0;
  @State tempIndex: number = 0;
  onConfirm: (result: MajorSelectorResult) => void = defaultOnConfirm;

  aboutToAppear(): void {
    this.tempIndex = this.initialIndex < 0 ? 0 : this.initialIndex;
  }

  build() {
    Column() {
      Text('选择专业')
        .fontSize(16)
        .fontWeight(FontWeight.Medium)
        .fontColor(AppColors.TEXT_PRIMARY)
        .margin({ top: 16, bottom: 8 })

      TextPicker({ range: this.majors.map((m: Major) => m.name), selected: this.tempIndex })
        .layoutWeight(1)
        .onChange((value: string | string[], index: number | number[]) => {
          this.tempIndex = index as number;
        })

      Row() {
        Button('取消')
          .layoutWeight(1)
          .height(44)
          .backgroundColor(AppColors.CARD)
          .fontColor(AppColors.TEXT_SECONDARY)
          .borderRadius(12)
          .onClick(() => {
            this.controller.close();
          })

        Blank()
          .width(12)

        Button('确定')
          .layoutWeight(1)
          .height(44)
          .backgroundColor(AppColors.PRIMARY)
          .fontColor(Color.White)
          .borderRadius(12)
          .onClick(() => {
            const idx: number = this.tempIndex < 0 ? 0 : this.tempIndex;
            const major: Major = this.majors[idx];
            this.onConfirm({ index: idx, value: major.name, majorId: major.id });
            this.controller.close();
          })
      }
      .width('100%')
      .padding({ left: 16, right: 16, bottom: 16, top: 8 })
    }
    .width('100%')
    .height(360)
    .backgroundColor(AppColors.BG)
    .borderRadius({ topLeft: 20, topRight: 20 })
  }
}

enum PageState {
  LOADING = 'LOADING',
  CONTENT = 'CONTENT',
  ERROR = 'ERROR'
}

@Entry
@Component
struct MeEditPage {
  @State pageState: PageState = PageState.LOADING;
  @State errorMsg: string = '';
  @State form: MeEditFormModel = MeEditFormModel.empty();
  @State showOldPwd: boolean = false;
  @State showNewPwd: boolean = false;
  @State showConfirmPwd: boolean = false;
  @State isSaving: boolean = false;

  @State majors: Major[] = [];
  @State isLoadingMajors: boolean = true;
  @State majorIndex: number = -1;

  private majorDialogController: CustomDialogController = new CustomDialogController({
    builder: MajorSelectorDialog({
      majors: $majors,
      initialIndex: this.majorIndex,
      onConfirm: (result: MajorSelectorResult): void => {
        this.majorIndex = result.index;
        this.form.majorId = result.majorId;
        this.form.majorName = result.value;
      }
    }),
    alignment: DialogAlignment.Bottom,
    customStyle: true,
    autoCancel: true,
    offset: { dx: 0, dy: 0 }
  });

  aboutToAppear(): void {
    this.loadData();
  }

  private async loadData(): Promise<void> {
    this.pageState = PageState.LOADING;
    this.loadMajors().then(() => {});
    const res = await meRepository.loadUserProfile();
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
    const profile: MeUserProfileModel = res.data;
    this.form = MeEditFormModel.fromProfile(profile);
    if (this.form.majorId > 0 && this.majors.length > 0) {
      const idx: number = this.findMajorIndex(this.form.majorId);
      if (idx >= 0) {
        this.majorIndex = idx;
      }
    }
    this.pageState = PageState.CONTENT;
  }

  private findMajorIndex(majorId: number): number {
    for (let i = 0; i < this.majors.length; i++) {
      if (this.majors[i].id === majorId) {
        return i;
      }
    }
    return -1;
  }

  private async loadMajors(): Promise<void> {
    this.isLoadingMajors = true;
    try {
      const res = await apiService.getMajors();
      if (res.code === 200 && res.data) {
        this.majors = res.data;
        if (this.form.majorId > 0) {
          const idx: number = this.findMajorIndex(this.form.majorId);
          if (idx >= 0) {
            this.majorIndex = idx;
          }
        }
      } else {
        ToastUtil.show(res.message || '加载专业列表失败');
      }
    } catch (e) {
      ToastUtil.show('加载专业列表失败，请检查网络');
    }
    this.isLoadingMajors = false;
  }

  private onRetry(): void {
    this.loadData();
  }

  private onBack(): void {
    if (this.isSaving) return;
    RouterUtil.back();
  }

  private onNicknameChange(val: string): void {
    this.form.nickname = val;
  }

  private onSchoolChange(val: string): void {
    this.form.schoolName = val;
  }

  private onOldPwdChange(val: string): void {
    this.form.oldPassword = val;
  }

  private onNewPwdChange(val: string): void {
    this.form.newPassword = val;
  }

  private onConfirmPwdChange(val: string): void {
    this.form.confirmNewPassword = val;
  }

  private nicknameCountDisplay(): string {
    const count: number = this.form.nickname.length;
    return `${count}/50`;
  }

  private toggleOldPwd(): void {
    this.showOldPwd = !this.showOldPwd;
  }

  private toggleNewPwd(): void {
    this.showNewPwd = !this.showNewPwd;
  }

  private toggleConfirmPwd(): void {
    this.showConfirmPwd = !this.showConfirmPwd;
  }

  private avatarDisplayText(): string {
    const name: string = this.form.nickname || '同学';
    return name.charAt(0);
  }

  private onChangeAvatar(): void {
    ToastUtil.show('头像上传功能开发中');
  }

  private onChangeMajor(): void {
    if (this.isLoadingMajors) {
      ToastUtil.show('专业列表加载中，请稍候');
      return;
    }
    if (this.majors.length === 0) {
      ToastUtil.show('专业列表加载失败，请重试');
      return;
    }
    this.majorDialogController.open();
  }

  private async onSaveClick(): Promise<void> {
    if (this.isSaving) return;
    const err: string = this.form.validate();
    if (err.length > 0) {
      ToastUtil.show(err);
      return;
    }
    const confirmMsg: string = this.form.passwordFieldsTouched()
      ? '确定要修改资料和密码吗？'
      : '确定要保存修改吗？';
    const ok: boolean = await this.showConfirm(confirmMsg);
    if (!ok) return;
    await this.doSave();
  }

  private async doSave(): Promise<void> {
    if (this.isSaving) return;
    this.isSaving = true;
    ToastUtil.show('保存中...');
    const res = await meRepository.updateProfile(this.form.toUpdateRequest());
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
    ToastUtil.show(res.message || '保存成功');
    setTimeout(() => RouterUtil.back(), 600);
  }

  private showConfirm(msg: string): Promise<boolean> {
    return new Promise((resolve: (v: boolean) => void) => {
      promptAction.showDialog({
        message: msg,
        buttons: [
          { text: '取消', color: '#666666' },
          { text: '确定', color: AppColors.PRIMARY }
        ]
      }, (err: Error, data: promptAction.ShowDialogSuccessResponse) => {
        if (err) {
          resolve(false);
          return;
        }
        const idx: number = Number(data && data['index']);
        resolve(idx === 1);
      });
    });
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

      Text('编辑资料')
        .fontSize(17)
        .fontWeight(FontWeight.Bold)
        .fontColor(AppColors.TEXT_PRIMARY)
        .layoutWeight(1)
        .textAlign(TextAlign.Center)
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
    }
    .width('100%')
    .height(56)
    .padding({ left: 8, right: 8 })
    .backgroundColor(Color.White)
  }

  @Builder
  AvatarSection() {
    Column({ space: 12 }) {
      Stack() {
        if (this.form.avatarUrl && this.form.avatarUrl.length > 0) {
          Row() {}
        } else {
          Text(this.avatarDisplayText())
            .fontSize(28)
            .fontWeight(FontWeight.Medium)
            .fontColor('#FFFFFF')
            .width(80)
            .height(80)
            .borderRadius(999)
            .textAlign(TextAlign.Center)
            .backgroundColor('rgba(255,255,255,0.3)')
            .border({ width: 3, color: 'rgba(255,255,255,0.6)' })
        }
        Row() {
          Text('✎')
            .fontSize(13)
            .width(28)
            .height(28)
            .borderRadius(999)
            .textAlign(TextAlign.Center)
            .backgroundColor('#FFFFFF')
        }
        .margin({ left: 60, top: 60 })
        .shadow({ radius: 6, color: 'rgba(0,0,0,0.15)' })
      }
      .width(88)
      .height(88)
      .onClick(() => this.onChangeAvatar())

      Text('点击更换头像')
        .fontSize(12)
        .fontColor('rgba(255,255,255,0.85)')
    }
    .width('100%')
    .padding({ top: 24, bottom: 24, left: 16, right: 16 })
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
      .width('100%')
      .fontSize(13)
      .fontWeight(FontWeight.Bold)
      .fontColor(AppColors.TEXT_SECONDARY)
      .margin({ left: 4, bottom: 8, top: 0 })
  }

  @Builder
  FormDivider() {
    Divider()
      .color(AppColors.DIVIDER)
      .strokeWidth(1)
      .margin({ left: 16, right: 16 })
  }

  @Builder
  NicknameRow() {
    Row({ space: 12 }) {
      Text('昵称')
        .fontSize(14)
        .fontWeight(FontWeight.Medium)
        .fontColor(AppColors.TEXT_SECONDARY)
        .width(64)

      TextInput({
        placeholder: '请输入昵称',
        text: this.form.nickname
      })
        .layoutWeight(1)
        .fontSize(15)
        .fontColor(AppColors.TEXT_PRIMARY)
        .placeholderColor(AppColors.TEXT_HINT)
        .maxLength(50)
        .backgroundColor(Color.Transparent)
        .border({ width: 0 })
        .textAlign(TextAlign.Start)
        .onChange((val: string) => this.onNicknameChange(val))

      Text(this.nicknameCountDisplay())
        .fontSize(12)
        .fontColor(AppColors.TEXT_HINT)
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 16, bottom: 16 })
  }

  @Builder
  SchoolRow() {
    Row({ space: 12 }) {
      Text('学校')
        .fontSize(14)
        .fontWeight(FontWeight.Medium)
        .fontColor(AppColors.TEXT_SECONDARY)
        .width(64)
      TextInput({
        placeholder: '请输入学校名称',
        text: this.form.schoolName
      })
        .layoutWeight(1)
        .fontSize(15)
        .fontColor(AppColors.TEXT_PRIMARY)
        .placeholderColor(AppColors.TEXT_HINT)
        .backgroundColor(Color.Transparent)
        .border({ width: 0 })
        .textAlign(TextAlign.Start)
        .onChange((val: string) => this.onSchoolChange(val))
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 16, bottom: 16 })
  }

  @Builder
  MajorRow() {
    Row({ space: 12 }) {
      Text('专业')
        .fontSize(14)
        .fontWeight(FontWeight.Medium)
        .fontColor(AppColors.TEXT_SECONDARY)
        .width(64)
      if (this.majorIndex >= 0 && this.form.majorName.length > 0) {
        Text(this.form.majorName)
          .fontSize(15)
          .fontColor(AppColors.TEXT_PRIMARY)
          .layoutWeight(1)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
      } else {
        Text(this.isLoadingMajors ? '加载中...' : '请选择专业')
          .fontSize(15)
          .fontColor(AppColors.TEXT_HINT)
          .layoutWeight(1)
      }
      if (!this.isLoadingMajors) {
        Text('›')
          .fontSize(18)
          .fontColor(AppColors.TEXT_HINT)
      }
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 16, bottom: 16 })
    .onClick(() => this.onChangeMajor())
  }

  @Builder
  PasswordField(label: string, value: string, placeholder: string,
    show: boolean, onToggle: () => void, onChange: (s: string) => void) {
    Row({ space: 12 }) {
      Text(label)
        .fontSize(14)
        .fontWeight(FontWeight.Medium)
        .fontColor(AppColors.TEXT_SECONDARY)
        .width(72)
      TextInput({
        placeholder: placeholder,
        text: value
      })
        .type(show ? InputType.Normal : InputType.Password)
        .layoutWeight(1)
        .fontSize(15)
        .fontColor(AppColors.TEXT_PRIMARY)
        .placeholderColor(AppColors.TEXT_HINT)
        .backgroundColor(Color.Transparent)
        .border({ width: 0 })
        .textAlign(TextAlign.Start)
        .onChange((val: string) => onChange(val))
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 16, bottom: 16 })
  }

  @Builder
  PasswordHintBar() {
    Row({ space: 8 }) {
      Text('💡')
        .fontSize(12)
        .margin({ top: 1 })
      Column({ space: 2 }) {
        Text('不修改密码请留空，留空不提交该字段')
          .fontSize(11)
          .fontColor(AppColors.PRIMARY)
          .width('100%')
        Text('新密码长度 8–20 位，须同时包含字母和数字')
          .fontSize(11)
          .fontColor(AppColors.PRIMARY)
          .width('100%')
      }
      .layoutWeight(1)
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 10, bottom: 10 })
    .backgroundColor('#EFF4FF')
  }

  @Builder
  SaveButton() {
    Text('保存修改')
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
      this.AvatarSection()

      Column({ space: 0 }) {
        this.SectionLabel('基本信息')
        Column() {
          this.NicknameRow()
          this.FormDivider()
          this.SchoolRow()
          this.FormDivider()
          this.MajorRow()
        }
        .width('100%')
        .backgroundColor(AppColors.CARD)
        .border({ width: 1, color: AppColors.DIVIDER })
        .borderRadius(18)
        .shadow({ radius: 12, color: 'rgba(0,0,0,0.04)' })
      }
      .width('100%')

      Column({ space: 0 }) {
        this.SectionLabel('修改密码（选填）')
        Column() {
          this.PasswordField('原密码', this.form.oldPassword, '请输入原密码',
            this.showOldPwd, () => this.toggleOldPwd(), (s: string) => this.onOldPwdChange(s))
          this.FormDivider()
          this.PasswordField('新密码', this.form.newPassword, '8-20位，含字母与数字',
            this.showNewPwd, () => this.toggleNewPwd(), (s: string) => this.onNewPwdChange(s))
          this.FormDivider()
          this.PasswordField('确认密码', this.form.confirmNewPassword, '再次输入新密码',
            this.showConfirmPwd, () => this.toggleConfirmPwd(), (s: string) => this.onConfirmPwdChange(s))
          this.PasswordHintBar()
        }
        .width('100%')
        .backgroundColor(AppColors.CARD)
        .border({ width: 1, color: AppColors.DIVIDER })
        .borderRadius(18)
        .shadow({ radius: 12, color: 'rgba(0,0,0,0.04)' })
      }
      .width('100%')

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
