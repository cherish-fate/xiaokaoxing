import { UpdateUserMeRequest } from '../api/ApiService';
import { MeUserProfileModel } from './MeModel';

@Observed
export class MeEditFormModel {
  nickname: string;
  schoolName: string;
  majorId: number;
  majorName: string;
  avatarUrl: string | null;
  oldPassword: string;
  newPassword: string;
  confirmNewPassword: string;

  constructor(
    nickname: string = '',
    schoolName: string = '',
    majorId: number = 0,
    majorName: string = '',
    avatarUrl: string | null = null,
    oldPassword: string = '',
    newPassword: string = '',
    confirmNewPassword: string = ''
  ) {
    this.nickname = nickname;
    this.schoolName = schoolName;
    this.majorId = majorId;
    this.majorName = majorName;
    this.avatarUrl = avatarUrl;
    this.oldPassword = oldPassword;
    this.newPassword = newPassword;
    this.confirmNewPassword = confirmNewPassword;
  }

  static fromProfile(profile: MeUserProfileModel): MeEditFormModel {
    return new MeEditFormModel(
      profile.nickname,
      profile.schoolName,
      profile.majorId,
      profile.majorName,
      profile.avatarUrl
    );
  }

  static empty(): MeEditFormModel {
    return new MeEditFormModel();
  }

  passwordFieldsTouched(): boolean {
    return (this.oldPassword.length > 0
      || this.newPassword.length > 0
      || this.confirmNewPassword.length > 0);
  }

  validate(): string {
    const trimmedNickname: string = this.nickname.trim();
    if (trimmedNickname.length === 0) {
      return '昵称不能为空';
    }
    if (trimmedNickname.length > 50) {
      return '昵称不能超过 50 个字符';
    }
    const trimmedSchool: string = this.schoolName.trim();
    if (trimmedSchool.length === 0) {
      return '学校名称不能为空';
    }
    if (this.majorId <= 0) {
      return '请选择专业';
    }

    if (this.passwordFieldsTouched()) {
      if (this.oldPassword.length === 0) {
        return '请输入原密码';
      }
      if (this.newPassword.length === 0) {
        return '请输入新密码';
      }
      if (this.confirmNewPassword.length === 0) {
        return '请再次输入新密码';
      }
      if (this.newPassword.length < 8 || this.newPassword.length > 20) {
        return '新密码长度需在 8–20 位之间';
      }
      if (!this.isValidPassword(this.newPassword)) {
        return '新密码须同时包含字母和数字';
      }
      if (this.newPassword !== this.confirmNewPassword) {
        return '两次输入的新密码不一致';
      }
      if (this.oldPassword === this.newPassword) {
        return '新密码不能与原密码相同';
      }
    }

    return '';
  }

  isValidPassword(pwd: string): boolean {
    let hasLetter: boolean = false;
    let hasDigit: boolean = false;
    for (let i = 0; i < pwd.length; i++) {
      const ch: string = pwd.charAt(i);
      if ((ch >= 'a' && ch <= 'z') || (ch >= 'A' && ch <= 'Z')) {
        hasLetter = true;
      } else if (ch >= '0' && ch <= '9') {
        hasDigit = true;
      }
    }
    return hasLetter && hasDigit;
  }

  toUpdateRequest(): UpdateUserMeRequest {
    const req: UpdateUserMeRequest = {};
    req.nickname = this.nickname.trim();
    req.school_name = this.schoolName.trim();
    if (this.majorId > 0) {
      req.major_id = this.majorId;
    }
    if (this.avatarUrl !== undefined) {
      req.avatar_url = this.avatarUrl;
    }

    if (this.passwordFieldsTouched()) {
      req.old_password = this.oldPassword;
      req.new_password = this.newPassword;
      req.confirm_new_password = this.confirmNewPassword;
    }
    return req;
  }
}
