import apiService from './apiService';

export interface Company {
  _id: string;
  name: string;
  domain: string;
  status: string;
  subscriptionPlan?: {
    _id: string;
    name: string;
    price: number;
  };
  employeeCount?: number;
  adminCount?: number;
}

export interface CompaniesResponse {
  companies: Company[];
  totalPages: number;
  currentPage: number;
  total: number;
}

class CompanyService {
  /**
   * Get all companies
   */
  async getCompanies(): Promise<Company[]> {
    try {
      const response = await apiService.get<CompaniesResponse>('/api/super-admin/companies');
      return response.companies || [];
    } catch (error) {
      console.error('Error fetching companies:', error);
      throw error;
    }
  }

  /**
   * Get companies for dropdown (simplified version)
   */
  async getCompaniesForDropdown(): Promise<{ value: string; label: string }[]> {
    try {
      const companies = await this.getCompanies();
      return companies.map(company => ({
        value: company._id,
        label: `${company.name} (${company.domain})`
      }));
    } catch (error) {
      console.error('Error fetching companies for dropdown:', error);
      throw error;
    }
  }
}

const companyService = new CompanyService();
export default companyService; 