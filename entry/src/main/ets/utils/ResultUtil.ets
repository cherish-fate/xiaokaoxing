export class ResultCode {
  static readonly SUCCESS: number = 200;
  static readonly CREATED: number = 201;
  static readonly BAD_REQUEST: number = 400;
  static readonly UNAUTHORIZED: number = 401;
  static readonly NOT_FOUND: number = 404;
  static readonly SERVER_ERROR: number = 500;
}

export interface AsyncResult<T> {
  success: boolean;
  code: number;
  message: string;
  data: T | null;
}

export class ResultUtil {
  static success<T>(data: T, message: string = 'success'): AsyncResult<T> {
    return { success: true, code: 200, message, data };
  }

  static fail<T>(code: number, message: string, data: T | null = null): AsyncResult<T> {
    return { success: false, code, message, data };
  }

  static map<T>(code: number, message: string, data: T): AsyncResult<T> {
    return {
      success: code === 200 || code === 201,
      code,
      message: message || '',
      data
    };
  }
}
