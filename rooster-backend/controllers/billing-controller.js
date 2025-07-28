const Company = require('../models/Company');
const User = require('../models/User');
const { Logger } = require('../config/logger');

class BillingController {
  // Get all payments
  static async getPayments(req, res) {
    try {
      // For now, return mock data. In production, this would query a payments table
      const payments = [
        {
          id: '1',
          companyId: 'comp1',
          companyName: 'TechCorp Solutions',
          amount: 299.99,
          currency: 'USD',
          status: 'completed',
          paymentMethod: 'Stripe',
          transactionId: 'txn_123456789',
          date: new Date().toISOString(),
          description: 'Monthly subscription payment'
        },
        {
          id: '2',
          companyId: 'comp2',
          companyName: 'Global Industries',
          amount: 499.99,
          currency: 'USD',
          status: 'pending',
          paymentMethod: 'PayPal',
          transactionId: 'txn_987654321',
          date: new Date(Date.now() - 86400000).toISOString(),
          description: 'Annual subscription payment'
        }
      ];

      res.json({ payments });
    } catch (error) {
      Logger.error('Error fetching payments:', error);
      res.status(500).json({ message: 'Failed to fetch payments' });
    }
  }

  // Get all invoices
  static async getInvoices(req, res) {
    try {
      // For now, return mock data. In production, this would query an invoices table
      const invoices = [
        {
          id: '1',
          companyId: 'comp1',
          companyName: 'TechCorp Solutions',
          invoiceNumber: 'INV-2024-001',
          amount: 299.99,
          currency: 'USD',
          status: 'paid',
          dueDate: new Date().toISOString(),
          issueDate: new Date(Date.now() - 7 * 86400000).toISOString(),
          items: [
            { description: 'Professional Plan - Monthly', quantity: 1, unitPrice: 299.99, total: 299.99 }
          ]
        },
        {
          id: '2',
          companyId: 'comp2',
          companyName: 'Global Industries',
          invoiceNumber: 'INV-2024-002',
          amount: 499.99,
          currency: 'USD',
          status: 'sent',
          dueDate: new Date(Date.now() + 30 * 86400000).toISOString(),
          issueDate: new Date().toISOString(),
          items: [
            { description: 'Enterprise Plan - Annual', quantity: 1, unitPrice: 499.99, total: 499.99 }
          ]
        }
      ];

      res.json({ invoices });
    } catch (error) {
      Logger.error('Error fetching invoices:', error);
      res.status(500).json({ message: 'Failed to fetch invoices' });
    }
  }

  // Get all subscriptions
  static async getSubscriptions(req, res) {
    try {
      // Get real subscription data from companies
      const companies = await Company.find({ isActive: true }).select('name subscriptionPlan nextBillingDate billingCycle');
      
      const subscriptions = companies.map((company, index) => ({
        id: company._id.toString(),
        companyId: company._id.toString(),
        companyName: company.name,
        planName: company.subscriptionPlan || 'Basic',
        status: company.isActive ? 'active' : 'cancelled',
        currentPeriodStart: company.createdAt.toISOString(),
        currentPeriodEnd: company.nextBillingDate ? company.nextBillingDate.toISOString() : new Date(Date.now() + 30 * 86400000).toISOString(),
        amount: this.getPlanAmount(company.subscriptionPlan),
        currency: 'USD',
        billingCycle: company.billingCycle || 'monthly',
        nextBillingDate: company.nextBillingDate ? company.nextBillingDate.toISOString() : new Date(Date.now() + 30 * 86400000).toISOString()
      }));

      res.json({ subscriptions });
    } catch (error) {
      Logger.error('Error fetching subscriptions:', error);
      res.status(500).json({ message: 'Failed to fetch subscriptions' });
    }
  }

  // Get billing statistics
  static async getBillingStats(req, res) {
    try {
      const companies = await Company.find({ isActive: true });
      const activeSubscriptions = companies.length;
      
      // Calculate mock statistics based on active companies
      const stats = {
        totalRevenue: activeSubscriptions * 299.99, // Mock calculation
        monthlyRevenue: Math.floor(activeSubscriptions * 299.99 * 0.8), // Mock calculation
        pendingPayments: Math.floor(activeSubscriptions * 0.1), // 10% pending
        overdueInvoices: Math.floor(activeSubscriptions * 0.05), // 5% overdue
        activeSubscriptions: activeSubscriptions,
        failedPayments: Math.floor(activeSubscriptions * 0.02) // 2% failed
      };

      res.json({ stats });
    } catch (error) {
      Logger.error('Error fetching billing stats:', error);
      res.status(500).json({ message: 'Failed to fetch billing statistics' });
    }
  }

  // Generate invoice for a company
  static async generateInvoice(req, res) {
    try {
      const { companyId } = req.body;
      
      if (!companyId) {
        return res.status(400).json({ message: 'Company ID is required' });
      }

      const company = await Company.findById(companyId);
      if (!company) {
        return res.status(404).json({ message: 'Company not found' });
      }

      // Generate invoice logic would go here
      // For now, return success
      res.json({ 
        message: 'Invoice generated successfully',
        invoiceId: `INV-${Date.now()}`,
        companyName: company.name
      });
    } catch (error) {
      Logger.error('Error generating invoice:', error);
      res.status(500).json({ message: 'Failed to generate invoice' });
    }
  }

  // Send invoice
  static async sendInvoice(req, res) {
    try {
      const { invoiceId } = req.params;
      
      // Send invoice logic would go here
      // For now, return success
      res.json({ 
        message: 'Invoice sent successfully',
        invoiceId: invoiceId
      });
    } catch (error) {
      Logger.error('Error sending invoice:', error);
      res.status(500).json({ message: 'Failed to send invoice' });
    }
  }

  // Download invoice
  static async downloadInvoice(req, res) {
    try {
      const { invoiceId } = req.params;
      const { format = 'pdf' } = req.query;
      
      // Download invoice logic would go here
      // For now, return a mock PDF
      const mockPdfContent = `Mock PDF content for invoice ${invoiceId}`;
      
      res.setHeader('Content-Type', 'application/pdf');
      res.setHeader('Content-Disposition', `attachment; filename="invoice-${invoiceId}.pdf"`);
      res.send(Buffer.from(mockPdfContent));
    } catch (error) {
      Logger.error('Error downloading invoice:', error);
      res.status(500).json({ message: 'Failed to download invoice' });
    }
  }

  // Helper method to get plan amount
  static getPlanAmount(planName) {
    const planAmounts = {
      'Basic': 99.99,
      'Professional': 299.99,
      'Enterprise': 499.99,
      'Custom': 799.99
    };
    return planAmounts[planName] || 299.99;
  }
}

module.exports = BillingController; 