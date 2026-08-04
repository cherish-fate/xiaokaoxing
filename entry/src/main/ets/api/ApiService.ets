import http from '@ohos.net.http';
import preferences  from '@ohos.data.preferences';

const BASE_URL: string = 'http://10.0.2.2:3000';

interface ApiResponse<T> {
  code: number;
  message: string;
  data: T | null;
}

interface Major {
  id: number;
  name: string;
}

interface RegisterRequest {
  nickname: string;
  email: string;
  password: string;
  school_name: string;
  major_id: number;
}

interface RegisterData {
  id: number;
  nickname: string;
  email: string;
  school_name: string;
  major_id: number;
  avatar_url: string | null;
  created_at: string;
}

interface LoginRequest {
  email: string;
  password: string;
}

interface UserInfo {
  id: number;
  email: string;
  nickname: string;
  school_name: string;
  major_id: number;
  avatar_url: string | null;
  created_at: string;
  updated_at: string;
}

interface AuthData {
  id: number;
  nickname: string;
  email: string;
  school_name: string;
  major_id: number;
  avatar_url: string | null;
  created_at: string;
  updated_at: string;
  token: string;
}

class ApiService {
  private httpRequest: http.HttpRequest | null = null;

  getBaseUrl(): string {
    return BASE_URL;
  }

  async getToken(): Promise<string> {
    try {
      const pref = await preferences.getPreferences(getContext(), 'user_prefs');
      return (await pref.get('token', '')) as string;
    } catch (e) {
      return '';
    }
  }

  async saveToken(token: string): Promise<void> {
    try {
      const pref = await preferences.getPreferences(getContext(), 'user_prefs');
      await pref.put('token', token);
      await pref.flush();
    } catch (e) {
      console.error('保存token失败:', JSON.stringify(e));
    }
  }

  private async request<T>(path: string, method: http.RequestMethod, body: object | null = null, needAuth: boolean = false): Promise<ApiResponse<T>> {
    if (!this.httpRequest) {
      this.httpRequest = http.createHttp();
    }

    const url: string = `${BASE_URL}${path}`;
    const headers: Record<string, string> = {
      'Content-Type': 'application/json'
    };

    if (needAuth) {
      const token = await this.getToken();
      if (token) {
        headers['Authorization'] = `Bearer ${token}`;
      }
    }

    const requestOptions: http.HttpRequestOptions = {
      method: method,
      header: headers,
      connectTimeout: 10000,
      readTimeout: 10000
    };

    if (body) {
      requestOptions.extraData = JSON.stringify(body);
    }

    try {
      const response = await this.httpRequest.request(url, requestOptions);
      const result: ApiResponse<T> = JSON.parse(response.result as string);
      return result;
    } catch (error) {
      console.error(`HTTP请求失败: ${url}, 错误: ${JSON.stringify(error)}`);
      return {
        code: 500,
        message: '网络请求失败，请检查网络连接',
        data: null
      };
    }
  }

  async getMajors(): Promise<ApiResponse<Major[]>> {
    return this.request<Major[]>('/api/majors', http.RequestMethod.GET);
  }

  async register(req: RegisterRequest): Promise<ApiResponse<RegisterData>> {
    return this.request<RegisterData>('/api/users/register', http.RequestMethod.POST, req);
  }

  async login(req: LoginRequest): Promise<ApiResponse<AuthData>> {
    return this.request<AuthData>('/api/users/login', http.RequestMethod.POST, req);
  }

  destroy(): void {
    if (this.httpRequest) {
      this.httpRequest.destroy();
      this.httpRequest = null;
    }
  }
}

export const apiService: ApiService = new ApiService();
export type { Major, RegisterRequest, RegisterData, ApiResponse, LoginRequest, AuthData, UserInfo };
