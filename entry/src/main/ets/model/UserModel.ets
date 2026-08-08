import { DateUtil } from '../utils/DateUtil';

export class UserModel {
  id: number;
  nickname: string;
  avatarUrl: string;

  constructor(id: number, nickname: string, avatarUrl: string) {
    this.id = id;
    this.nickname = nickname;
    this.avatarUrl = avatarUrl;
  }

  static empty(): UserModel {
    return new UserModel(0, '同学', '');
  }

  displayName(): string {
    return this.nickname && this.nickname.length > 0 ? this.nickname : '同学';
  }

  hasAvatar(): boolean {
    return !!this.avatarUrl;
  }
}

export class GreetingModel {
  greeting: string;
  user: UserModel;

  constructor(user: UserModel, hour: number = new Date().getHours()) {
    this.user = user;
    this.greeting = DateUtil.greetingByHour(hour);
  }

  displayText(): string {
    return `${this.greeting}，${this.user.displayName()}`;
  }
}
