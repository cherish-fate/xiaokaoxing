import http from '@ohos.net.http';
import { Logger } from '../utils/Logger';
import { StorageUtil } from '../utils/StorageUtil';

const TAG = 'ApiService';
const BASE_URL: string = 'http://10.0.2.2:3000';

export interface ApiResponse<T> {
  code: number;
  message: string;
  data: T | null;
}

export interface Major {
  id: number;
  name: string;
}

export interface RegisterRequest {
  nickname: string;
  email: string;
  password: string;
  school_name: string;
  major_id: number;
}

export interface RegisterData {
  id: number;
  nickname: string;
  email: string;
  school_name: string;
  major_id: number;
  avatar_url: string | null;
  created_at: string;
}

export interface LoginRequest {
  email: string;
  password: string;
}

export interface UserInfo {
  id: number;
  email: string;
  nickname: string;
  school_name: string;
  major_id: number;
  avatar_url: string | null;
  created_at: string;
  updated_at: string;
}

export interface AuthData {
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

export interface ExamCountdown {
  has_exam: boolean;
  exam_name: string;
  exam_date: string;
  start_time: string;
  end_time: string;
  countdown_days: number;
  countdown_text: string;
}

export interface TodayProgress {
  completed: number;
  total: number;
  progress_percentage: number;
}

export interface RecentExamItem {
  id: number;
  name: string;
  exam_date: string;
  start_time: string;
  end_time: string;
  location: string;
  days_remaining: number;
  days_text: string;
}

export interface ExamItem {
  id: number;
  name: string;
  exam_date: string;
  start_time: string;
  end_time: string;
  location: string;
  is_completed: boolean;
  days_remaining: number;
  days_text: string;
  status: string;
}

export interface TaskItem {
  id: number;
  task_name: string;
  plan_date: string;
  is_completed: boolean;
}

export interface ResourceItem {
  id: number;
  title: string;
  type_tag: string;
  description: string;
  file_url?: string;
}

interface userInterface {
  id: number;
  nickname: string;
  avatar_url: string | null;
}

export interface HomeAggregate {
  user: userInterface;
  exam_countdown: ExamCountdown;
  today_progress: TodayProgress;
  recent_exams: RecentExamItem[];
  today_tasks: TaskItem[];
  recommended_resources: ResourceItem[];
}

export interface ExamListResponse {
  total: number;
  list: ExamItem[];
}

export interface TodayTaskResponse {
  has_tasks: boolean;
  total: number;
  completed: number;
  list: TaskItem[];
  empty_hint?: string;
}

export interface ResourceListResponse {
  total: number;
  list: ResourceItem[];
  empty_hint?: string;
}

export interface CreateExamRequest {
  name: string;
  exam_date: string;
  start_time: string;
  end_time?: string;
  location?: string;
  is_completed?: boolean;
}

export interface UpdateExamRequest {
  name?: string;
  exam_date?: string;
  start_time?: string;
  end_time?: string;
  location?: string;
  is_completed?: boolean;
}

export interface CreateTaskRequest {
  task_name: string;
  plan_date?: string;
  is_completed?: boolean;
}

export interface UpdateTaskRequest {
  task_name?: string;
  plan_date?: string;
  is_completed?: boolean;
}

class ApiService {
  private httpRequest: http.HttpRequest | null = null;

  getBaseUrl(): string {
    return BASE_URL;
  }

  async getToken(): Promise<string> {
    return StorageUtil.getString('token', '');
  }

  async saveToken(token: string): Promise<void> {
    await StorageUtil.put('token', token);
  }

  private async request<T>(
    path: string,
    method: http.RequestMethod,
    body: object | null = null,
    needAuth: boolean = false,
    query: Record<string, string | number> | null = null
  ): Promise<ApiResponse<T>> {
    if (!this.httpRequest) {
      this.httpRequest = http.createHttp();
    }

    let url: string = `${BASE_URL}${path}`;
    if (query && Object.keys(query).length > 0) {
      const qs = Object.keys(query)
        .map(k => `${encodeURIComponent(k)}=${encodeURIComponent(String(query[k]))}`)
        .join('&');
      url = `${url}?${qs}`;
    }

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
      Logger.error(TAG, `HTTP请求失败: ${url}`, error as Error);
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

  async fetchHome(): Promise<ApiResponse<HomeAggregate>> {
    return this.request<HomeAggregate>('/api/home', http.RequestMethod.GET, null, true);
  }

  async fetchExams(
    limit: number = 3,
    status: string = ''
  ): Promise<ApiResponse<ExamListResponse>> {
    const query: Record<string, string | number> = {};
    query['limit'] = limit;
    if (status) {
      query['status'] = status;
    }
    return this.request<ExamListResponse>('/api/exams', http.RequestMethod.GET, null, true, query);
  }

  async createExam(req: CreateExamRequest): Promise<ApiResponse<ExamItem>> {
    return this.request<ExamItem>('/api/exams', http.RequestMethod.POST, req, true);
  }

  async updateExam(id: number, req: UpdateExamRequest): Promise<ApiResponse<ExamItem>> {
    return this.request<ExamItem>(`/api/exams/${id}`, http.RequestMethod.PUT, req, true);
  }

  async deleteExam(id: number): Promise<ApiResponse<null>> {
    return this.request<null>(`/api/exams/${id}`, http.RequestMethod.DELETE, null, true);
  }

  async fetchTodayTasks(): Promise<ApiResponse<TodayTaskResponse>> {
    return this.request<TodayTaskResponse>('/api/tasks/today', http.RequestMethod.GET, null, true);
  }

  async createTask(req: CreateTaskRequest): Promise<ApiResponse<TaskItem>> {
    return this.request<TaskItem>('/api/tasks', http.RequestMethod.POST, req, true);
  }

  async updateTask(id: number, req: UpdateTaskRequest): Promise<ApiResponse<TaskItem>> {
    return this.request<TaskItem>(`/api/tasks/${id}`, http.RequestMethod.PUT, req, true);
  }

  async deleteTask(id: number): Promise<ApiResponse<null>> {
    return this.request<null>(`/api/tasks/${id}`, http.RequestMethod.DELETE, null, true);
  }

  async fetchRecommendedResources(limit: number = 4): Promise<ApiResponse<ResourceListResponse>> {
    return this.request<ResourceListResponse>(
      '/api/resources/recommended',
      http.RequestMethod.GET,
      null,
      true,
    );
  }

  destroy(): void {
    if (this.httpRequest) {
      this.httpRequest.destroy();
      this.httpRequest = null;
    }
  }
}

export const apiService: ApiService = new ApiService();
// export type {
//   Major,
//   RegisterRequest,
//   RegisterData,
//   ApiResponse,
//   LoginRequest,
//   AuthData,
//   UserInfo
// };
