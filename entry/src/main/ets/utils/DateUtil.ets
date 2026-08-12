export class DateUtil {
  static today(): string {
    const d = new Date();
    return DateUtil.format(d);
  }

  static format(date: Date): string {
    const y = date.getFullYear();
    const m = `${date.getMonth() + 1}`.padStart(2, '0');
    const day = `${date.getDate()}`.padStart(2, '0');
    return `${y}-${m}-${day}`;
  }

  static greetingByHour(hour: number): string {
    if (hour >= 6 && hour < 12) {
      return '早安';
    } else if (hour >= 12 && hour < 18) {
      return '午安';
    } else {
      return '晚安';
    }
  }

  static countdownText(days: number): string {
    if (days < 0) {
      return '已过期';
    }
    if (days === 0) {
      return '今天';
    }
    if (days === 1) {
      return '1天后';
    }
    return `${days}天后`;
  }

  static diffDays(targetDateStr: string): number {
    if (!targetDateStr) {
      return 0;
    }
    const today = new Date();
    today.setHours(0, 0, 0, 0);
    const parts = targetDateStr.split('-');
    if (parts.length !== 3) {
      return 0;
    }
    const target = new Date(Number(parts[0]), Number(parts[1]) - 1, Number(parts[2]));
    const diff = target.getTime() - today.getTime();
    return Math.floor(diff / (24 * 60 * 60 * 1000));
  }

  static timeRangeText(start: string, end: string): string {
    if (end) {
      return `${start}-${end}`;
    }
    return start;
  }

  static toShortDate(longDate: string): string {
    if (!longDate) return '';
    if (longDate.length >= 10) {
      return longDate.substring(2);
    }
    if (longDate.length >= 8) {
      return longDate;
    }
    return longDate;
  }

  static toShortDateTime(longDate: string): string {
    if (!longDate) return '';
    // 支持 ISO8601 格式：YYYY-MM-DDTHH:mm:ssZ 或 YYYY-MM-DD HH:mm:ss
    // 去掉末尾Z，保留 年-月-日 时:分
    const cleaned = longDate.replace('Z', '').replace('T', ' ');
    if (cleaned.length >= 16) {
      return cleaned.substring(5, 16); // MM-DD HH:mm
    }
    if (cleaned.length >= 10) {
      return cleaned.substring(5); // MM-DD ...
    }
    return cleaned;
  }
}
