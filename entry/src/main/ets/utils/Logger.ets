export class Logger {
  private static readonly TAG: string = '[校考星]';
  static info(tag: string, msg: string): void {
    console.info(`${Logger.TAG}[${tag}] ${msg}`);
  }
  static warn(tag: string, msg: string): void {
    console.warn(`${Logger.TAG}[${tag}] ${msg}`);
  }
  static error(tag: string, msg: string, err?: Error | Object): void {
    console.error(`${Logger.TAG}[${tag}] ${msg} ${err ? JSON.stringify(err) : ''}`);
  }
}
