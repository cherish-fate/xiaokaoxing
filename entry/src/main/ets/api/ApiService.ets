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
  category?: string;
  is_hot?: boolean;
  author?: string;
  created_at?: string;
  view_count?: number;
  is_favorited?: boolean;
}

export interface RecommendationItem {
  id: number;
  emoji: string;
  description: string;
  suggestion: string;
  target_type: string;
  target_id: number;
}

export interface ResourceListData {
  total: number;
  list: ResourceItem[];
  keyword?: string;
}

export interface PrepHomeResponse {
  recommendations: RecommendationItem[];
  resources: ResourceListData;
}

export interface FavoriteRequest {
  is_favorited: boolean;
}

export interface FavoriteResponse {
  resource_id: number;
  is_favorited: boolean;
}

export interface AiChatRequest {
  message: string;
  conversation_id?: string;
  attachment_url?: string;
}

export interface AiUploadResponse {
  file_url: string;
  file_name: string;
  file_size: number;
}

interface SseChunkMessage {
  type: string;
  content?: string;
  conversation_id?: string;
  full_content?: string;
  message?: string;
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
  keyword?: string;
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

  async fetchPrepHome(
    category: string = '真题试卷',
    limit: number = 10,
    offset: number = 0
  ): Promise<ApiResponse<PrepHomeResponse>> {
    const query: Record<string, string | number> = {};
    query['category'] = category;
    query['limit'] = limit;
    query['offset'] = offset;
    return this.request<PrepHomeResponse>('/api/prep/home', http.RequestMethod.GET, null, true, query);
  }

  async fetchResources(
    category: string = '',
    limit: number = 10,
    offset: number = 0
  ): Promise<ApiResponse<ResourceListResponse>> {
    const query: Record<string, string | number> = {};
    query['limit'] = limit;
    query['offset'] = offset;
    if (category) {
      query['category'] = category;
    }
    return this.request<ResourceListResponse>('/api/resources', http.RequestMethod.GET, null, true, query);
  }

  async searchResources(
    keyword: string,
    limit: number = 10,
    offset: number = 0
  ): Promise<ApiResponse<ResourceListResponse>> {
    const query: Record<string, string | number> = {};
    query['keyword'] = keyword;
    query['limit'] = limit;
    query['offset'] = offset;
    return this.request<ResourceListResponse>('/api/resources/search', http.RequestMethod.GET, null, true, query);
  }

  async toggleFavorite(id: number, req: FavoriteRequest): Promise<ApiResponse<FavoriteResponse>> {
    return this.request<FavoriteResponse>(
      `/api/resources/${id}/favorite`,
      http.RequestMethod.POST,
      req,
      true
    );
  }

  async uploadAiFile(formData: ArrayBuffer, fileName: string): Promise<ApiResponse<AiUploadResponse>> {
    return this.requestMultipart<AiUploadResponse>(
      '/api/ai/upload',
      formData,
      fileName
    );
  }

  private async requestMultipart<T>(
    path: string,
    fileBuffer: ArrayBuffer,
    fileName: string
  ): Promise<ApiResponse<T>> {
    if (!this.httpRequest) {
      this.httpRequest = http.createHttp();
    }
    const url = `${BASE_URL}${path}`;
    const token = await this.getToken();
    const boundary = '---xiaokaoxing-boundary';
    const headerStr = '--' + boundary + '\r\nContent-Disposition: form-data; name="file"; filename="' + fileName + '"\r\nContent-Type: application/octet-stream\r\n\r\n';
    const footerStr = '\r\n--' + boundary + '--\r\n';
    const headerBytes = new Uint8Array(headerStr.length);
    for (let i = 0; i < headerStr.length; i++) headerBytes[i] = headerStr.charCodeAt(i);
    const footerBytes = new Uint8Array(footerStr.length);
    for (let i = 0; i < footerStr.length; i++) footerBytes[i] = footerStr.charCodeAt(i);
    const totalLen = headerBytes.length + fileBuffer.byteLength + footerBytes.length;
    const combined = new Uint8Array(totalLen);
    combined.set(headerBytes, 0);
    combined.set(new Uint8Array(fileBuffer), headerBytes.length);
    combined.set(footerBytes, headerBytes.length + fileBuffer.byteLength);
    const headers: Record<string, string> = {};
    headers['Content-Type'] = 'multipart/form-data; boundary=' + boundary;
    headers['Authorization'] = token ? 'Bearer ' + token : '';
    try {
      const response = await this.httpRequest.request(url, {
        method: http.RequestMethod.POST,
        header: headers,
        extraData: combined.buffer.slice(combined.byteOffset, combined.byteOffset + combined.byteLength) as ArrayBuffer,
        connectTimeout: 30000,
        readTimeout: 30000
      });
      const result: ApiResponse<T> = JSON.parse(response.result as string);
      return result;
    } catch (error) {
      Logger.error(TAG, `HTTP multipart请求失败: ${url}`, error as Error);
      return { code: 500, message: '文件上传失败', data: null };
    }
  }

  async chatStream(
    req: AiChatRequest,
    onChunk: (content: string) => void,
    onDone: (conversationId: string, fullContent: string) => void,
    onError: (msg: string) => void
  ): Promise<void> {
    if (!this.httpRequest) {
      this.httpRequest = http.createHttp();
    }
    const url = `${BASE_URL}/api/ai/chat`;
    const token = await this.getToken();
    const headers: Record<string, string> = {};
    headers['Content-Type'] = 'application/json';
    headers['Accept'] = 'text/event-stream';
    headers['Authorization'] = token ? `Bearer ${token}` : '';
    try {
      const response = await this.httpRequest.request(url, {
        method: http.RequestMethod.POST,
        header: headers,
        extraData: JSON.stringify(req),
        connectTimeout: 30000,
        readTimeout: 30000
      });
      const body = response.result as string;
      const lines = body.split('\n');
      let fullContent = '';
      let conversationId = '';
      for (const line of lines) {
        const trimmed = line.trim();
        if (trimmed.startsWith('data:')) {
          const payload = trimmed.substring(5).trim();
          if (!payload) continue;
          try {
            const obj: SseChunkMessage = JSON.parse(payload) as SseChunkMessage;
            if (obj.type === 'chunk') {
              fullContent += obj.content || '';
              onChunk(obj.content || '');
            } else if (obj.type === 'done') {
              conversationId = obj.conversation_id || '';
              if (obj.full_content) {
                fullContent = obj.full_content;
              }
              onDone(conversationId, fullContent);
            } else if (obj.type === 'error') {
              onError(obj.message || 'AI 服务错误');
            }
          } catch (e) {
            Logger.warn(TAG, `解析SSE消息失败: ${payload}`);
          }
        }
      }
      if (conversationId === '' && fullContent !== '') {
        onDone('', fullContent);
      }
    } catch (error) {
      Logger.error(TAG, `AI chat请求失败`, error as Error);
      onError('AI 服务暂时不可用，请稍后重试');
    }
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
