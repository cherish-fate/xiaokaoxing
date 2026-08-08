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
}
