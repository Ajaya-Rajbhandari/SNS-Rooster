import React, { useState, useEffect } from 'react';
import {
  Box,
  Typography,
  Paper,
  Card,
  CardContent,
  Alert,
  CircularProgress,
  Tabs,
  Tab,
  Button,
  TextField,
  Dialog,
  DialogTitle,
  DialogContent,
  DialogActions,
  FormControl,
  InputLabel,
  Select,
  MenuItem,
  Table,
  TableBody,
  TableCell,
  TableContainer,
  TableHead,
  TableRow,
  Chip,
  IconButton,
  Tooltip,

  Divider,
  List,
  ListItem,
  ListItemText,
  ListItemAvatar,
  Avatar,
  Badge
} from '@mui/material';
import {
  Payment as PaymentIcon,
  Receipt as ReceiptIcon,
  CreditCard as CreditCardIcon,
  AccountBalance as AccountBalanceIcon,
  TrendingUp as TrendingUpIcon,
  TrendingDown as TrendingDownIcon,
  Download as DownloadIcon,
  Email as EmailIcon,
  Refresh as RefreshIcon,
  Add as AddIcon,
  Edit as EditIcon,
  Delete as DeleteIcon,
  Visibility as VisibilityIcon,
  CheckCircle as CheckCircleIcon,
  Warning as WarningIcon,
  Error as ErrorIcon,
  Info as InfoIcon,
  AttachMoney as MoneyIcon,
  Business as BusinessIcon,
  People as PeopleIcon
} from '@mui/icons-material';
import apiService from '../services/apiService';

interface Payment {
  id: string;
  companyId: string;
  companyName: string;
  amount: number;
  currency: string;
  status: 'pending' | 'completed' | 'failed' | 'refunded';
  paymentMethod: string;
  transactionId: string;
  date: string;
  description: string;
}

interface Invoice {
  id: string;
  companyId: string;
  companyName: string;
  invoiceNumber: string;
  amount: number;
  currency: string;
  status: 'draft' | 'sent' | 'paid' | 'overdue' | 'cancelled';
  dueDate: string;
  issueDate: string;
  items: InvoiceItem[];
}

interface InvoiceItem {
  description: string;
  quantity: number;
  unitPrice: number;
  total: number;
}

interface Subscription {
  id: string;
  companyId: string;
  companyName: string;
  planName: string;
  status: 'active' | 'cancelled' | 'past_due' | 'trialing';
  currentPeriodStart: string;
  currentPeriodEnd: string;
  amount: number;
  currency: string;
  billingCycle: 'monthly' | 'yearly';
  nextBillingDate: string;
}

const BillingPage: React.FC = () => {
  const [activeTab, setActiveTab] = useState(0);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [payments, setPayments] = useState<Payment[]>([]);
  const [invoices, setInvoices] = useState<Invoice[]>([]);
  const [subscriptions, setSubscriptions] = useState<Subscription[]>([]);
  const [stats, setStats] = useState({
    totalRevenue: 0,
    monthlyRevenue: 0,
    pendingPayments: 0,
    overdueInvoices: 0,
    activeSubscriptions: 0,
    failedPayments: 0
  });

  // Dialog states
  const [invoiceDialogOpen, setInvoiceDialogOpen] = useState(false);
  const [paymentDialogOpen, setPaymentDialogOpen] = useState(false);
  const [selectedInvoice, setSelectedInvoice] = useState<Invoice | null>(null);
  const [selectedPayment, setSelectedPayment] = useState<Payment | null>(null);

  useEffect(() => {
    fetchBillingData();
  }, []);

  const fetchBillingData = async () => {
    try {
      setLoading(true);
      setError('');

      // Fetch all billing data
      const [paymentsRes, invoicesRes, subscriptionsRes, statsRes] = await Promise.all([
        apiService.get<any>('/api/super-admin/billing/payments'),
        apiService.get<any>('/api/super-admin/billing/invoices'),
        apiService.get<any>('/api/super-admin/billing/subscriptions'),
        apiService.get<any>('/api/super-admin/billing/stats')
      ]);

      setPayments(paymentsRes.payments || []);
      setInvoices(invoicesRes.invoices || []);
      setSubscriptions(subscriptionsRes.subscriptions || []);
      setStats(statsRes.stats || {
        totalRevenue: 0,
        monthlyRevenue: 0,
        pendingPayments: 0,
        overdueInvoices: 0,
        activeSubscriptions: 0,
        failedPayments: 0
      });
    } catch (err: any) {
      console.error('Error fetching billing data:', err);
      setError('Failed to load billing data');
      
      // Set mock data for development
      setPayments([
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
      ]);

      setInvoices([
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
        }
      ]);

      setSubscriptions([
        {
          id: '1',
          companyId: 'comp1',
          companyName: 'TechCorp Solutions',
          planName: 'Professional',
          status: 'active',
          currentPeriodStart: new Date(Date.now() - 30 * 86400000).toISOString(),
          currentPeriodEnd: new Date(Date.now() + 30 * 86400000).toISOString(),
          amount: 299.99,
          currency: 'USD',
          billingCycle: 'monthly',
          nextBillingDate: new Date(Date.now() + 30 * 86400000).toISOString()
        }
      ]);

      setStats({
        totalRevenue: 125000,
        monthlyRevenue: 45000,
        pendingPayments: 3,
        overdueInvoices: 2,
        activeSubscriptions: 45,
        failedPayments: 1
      });
    } finally {
      setLoading(false);
    }
  };

  const handleGenerateInvoice = async (companyId: string) => {
    try {
      await apiService.post('/api/super-admin/billing/invoices/generate', { companyId });
      fetchBillingData();
    } catch (error) {
      console.error('Error generating invoice:', error);
    }
  };

  const handleSendInvoice = async (invoiceId: string) => {
    try {
      await apiService.post(`/api/super-admin/billing/invoices/${invoiceId}/send`);
      fetchBillingData();
    } catch (error) {
      console.error('Error sending invoice:', error);
    }
  };

  const handleDownloadInvoice = async (invoiceId: string, format: 'pdf' | 'csv') => {
    try {
      const response = await apiService.get(`/api/super-admin/billing/invoices/${invoiceId}/download?format=${format}`, {
        responseType: 'blob'
      });
      
      const url = window.URL.createObjectURL(new Blob([response as BlobPart]));
      const link = document.createElement('a');
      link.href = url;
      link.setAttribute('download', `invoice-${invoiceId}.${format}`);
      document.body.appendChild(link);
      link.click();
      link.remove();
    } catch (error) {
      console.error('Error downloading invoice:', error);
    }
  };

  const getStatusColor = (status: string) => {
    switch (status) {
      case 'completed':
      case 'paid':
      case 'active':
        return 'success';
      case 'pending':
      case 'draft':
      case 'trialing':
        return 'warning';
      case 'failed':
      case 'overdue':
      case 'cancelled':
        return 'error';
      default:
        return 'default';
    }
  };

  const getStatusIcon = (status: string) => {
    switch (status) {
      case 'completed':
      case 'paid':
      case 'active':
        return <CheckCircleIcon />;
      case 'pending':
      case 'draft':
      case 'trialing':
        return <WarningIcon />;
      case 'failed':
      case 'overdue':
      case 'cancelled':
        return <ErrorIcon />;
      default:
        return <InfoIcon />;
    }
  };

  const formatCurrency = (amount: number, currency: string = 'USD') => {
    return new Intl.NumberFormat('en-US', {
      style: 'currency',
      currency: currency
    }).format(amount);
  };

  const formatDate = (dateString: string) => {
    return new Date(dateString).toLocaleDateString();
  };

  if (loading) {
    return (
      <Box sx={{ display: 'flex', justifyContent: 'center', alignItems: 'center', height: '50vh' }}>
        <CircularProgress />
      </Box>
    );
  }

  return (
    <Box sx={{ display: 'flex', flexDirection: 'column', gap: 2 }}>
      {/* Header */}
      <Paper sx={{ p: 2 }}>
        <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', mb: 1 }}>
          <Box>
            <Typography variant="h4" component="h1" gutterBottom sx={{ fontWeight: 700 }}>
              Billing & Payments
            </Typography>
            <Typography variant="body1" color="text.secondary">
              Manage payments, invoices, and subscription billing
            </Typography>
          </Box>
          <Button
            variant="outlined"
            startIcon={<RefreshIcon />}
            onClick={fetchBillingData}
          >
            Refresh
          </Button>
        </Box>
        {error && (
          <Alert severity="error" onClose={() => setError('')} sx={{ mt: 1 }}>
            {error}
          </Alert>
        )}
      </Paper>

      {/* Stats Cards */}
      <Box sx={{ display: 'grid', gridTemplateColumns: { xs: '1fr', sm: '1fr 1fr', md: '1fr 1fr 1fr 1fr' }, gap: 2 }}>
        <Card>
          <CardContent>
            <Box sx={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
              <Box>
                <Typography color="textSecondary" gutterBottom variant="body2">
                  Total Revenue
                </Typography>
                <Typography variant="h4" component="div" sx={{ fontWeight: 700 }}>
                  {formatCurrency(stats.totalRevenue)}
                </Typography>
              </Box>
              <MoneyIcon color="primary" sx={{ fontSize: 32 }} />
            </Box>
          </CardContent>
        </Card>
        <Card>
          <CardContent>
            <Box sx={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
              <Box>
                <Typography color="textSecondary" gutterBottom variant="body2">
                  Monthly Revenue
                </Typography>
                <Typography variant="h4" component="div" sx={{ fontWeight: 700 }}>
                  {formatCurrency(stats.monthlyRevenue)}
                </Typography>
              </Box>
              <TrendingUpIcon color="success" sx={{ fontSize: 32 }} />
            </Box>
          </CardContent>
        </Card>
        <Card>
          <CardContent>
            <Box sx={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
              <Box>
                <Typography color="textSecondary" gutterBottom variant="body2">
                  Active Subscriptions
                </Typography>
                <Typography variant="h4" component="div" sx={{ fontWeight: 700 }}>
                  {stats.activeSubscriptions}
                </Typography>
              </Box>
              <BusinessIcon color="primary" sx={{ fontSize: 32 }} />
            </Box>
          </CardContent>
        </Card>
        <Card>
          <CardContent>
            <Box sx={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
              <Box>
                <Typography color="textSecondary" gutterBottom variant="body2">
                  Pending Payments
                </Typography>
                <Typography variant="h4" component="div" sx={{ fontWeight: 700 }}>
                  {stats.pendingPayments}
                </Typography>
              </Box>
              <PaymentIcon color="warning" sx={{ fontSize: 32 }} />
            </Box>
          </CardContent>
        </Card>
      </Box>

      {/* Tabs */}
      <Paper sx={{ p: 2 }}>
        <Tabs value={activeTab} onChange={(e, newValue) => setActiveTab(newValue)} sx={{ mb: 2 }}>
          <Tab label="Payments" icon={<PaymentIcon />} />
          <Tab label="Invoices" icon={<ReceiptIcon />} />
          <Tab label="Subscriptions" icon={<CreditCardIcon />} />
        </Tabs>

        {/* Payments Tab */}
        {activeTab === 0 && (
          <Box>
            <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', mb: 2 }}>
              <Typography variant="h6">Payment History</Typography>
              <Button
                variant="contained"
                startIcon={<AddIcon />}
                onClick={() => setPaymentDialogOpen(true)}
              >
                Add Payment
              </Button>
            </Box>
            <TableContainer>
              <Table>
                <TableHead>
                  <TableRow>
                    <TableCell>Company</TableCell>
                    <TableCell>Amount</TableCell>
                    <TableCell>Status</TableCell>
                    <TableCell>Payment Method</TableCell>
                    <TableCell>Date</TableCell>
                    <TableCell>Actions</TableCell>
                  </TableRow>
                </TableHead>
                <TableBody>
                  {payments.map((payment) => (
                    <TableRow key={payment.id}>
                      <TableCell>{payment.companyName}</TableCell>
                      <TableCell>{formatCurrency(payment.amount, payment.currency)}</TableCell>
                      <TableCell>
                        <Chip
                          icon={getStatusIcon(payment.status)}
                          label={payment.status}
                          color={getStatusColor(payment.status) as any}
                          size="small"
                        />
                      </TableCell>
                      <TableCell>{payment.paymentMethod}</TableCell>
                      <TableCell>{formatDate(payment.date)}</TableCell>
                      <TableCell>
                        <Tooltip title="View Details">
                          <IconButton size="small" onClick={() => setSelectedPayment(payment)}>
                            <VisibilityIcon />
                          </IconButton>
                        </Tooltip>
                      </TableCell>
                    </TableRow>
                  ))}
                </TableBody>
              </Table>
            </TableContainer>
          </Box>
        )}

        {/* Invoices Tab */}
        {activeTab === 1 && (
          <Box>
            <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', mb: 2 }}>
              <Typography variant="h6">Invoice Management</Typography>
              <Button
                variant="contained"
                startIcon={<AddIcon />}
                onClick={() => setInvoiceDialogOpen(true)}
              >
                Generate Invoice
              </Button>
            </Box>
            <TableContainer>
              <Table>
                <TableHead>
                  <TableRow>
                    <TableCell>Invoice #</TableCell>
                    <TableCell>Company</TableCell>
                    <TableCell>Amount</TableCell>
                    <TableCell>Status</TableCell>
                    <TableCell>Due Date</TableCell>
                    <TableCell>Actions</TableCell>
                  </TableRow>
                </TableHead>
                <TableBody>
                  {invoices.map((invoice) => (
                    <TableRow key={invoice.id}>
                      <TableCell>{invoice.invoiceNumber}</TableCell>
                      <TableCell>{invoice.companyName}</TableCell>
                      <TableCell>{formatCurrency(invoice.amount, invoice.currency)}</TableCell>
                      <TableCell>
                        <Chip
                          icon={getStatusIcon(invoice.status)}
                          label={invoice.status}
                          color={getStatusColor(invoice.status) as any}
                          size="small"
                        />
                      </TableCell>
                      <TableCell>{formatDate(invoice.dueDate)}</TableCell>
                      <TableCell>
                        <Box sx={{ display: 'flex', gap: 1 }}>
                          <Tooltip title="View Invoice">
                            <IconButton size="small" onClick={() => setSelectedInvoice(invoice)}>
                              <VisibilityIcon />
                            </IconButton>
                          </Tooltip>
                          <Tooltip title="Download PDF">
                            <IconButton size="small" onClick={() => handleDownloadInvoice(invoice.id, 'pdf')}>
                              <DownloadIcon />
                            </IconButton>
                          </Tooltip>
                          <Tooltip title="Send Invoice">
                            <IconButton size="small" onClick={() => handleSendInvoice(invoice.id)}>
                              <EmailIcon />
                            </IconButton>
                          </Tooltip>
                        </Box>
                      </TableCell>
                    </TableRow>
                  ))}
                </TableBody>
              </Table>
            </TableContainer>
          </Box>
        )}

        {/* Subscriptions Tab */}
        {activeTab === 2 && (
          <Box>
            <Typography variant="h6" sx={{ mb: 2 }}>Subscription Management</Typography>
            <TableContainer>
              <Table>
                <TableHead>
                  <TableRow>
                    <TableCell>Company</TableCell>
                    <TableCell>Plan</TableCell>
                    <TableCell>Status</TableCell>
                    <TableCell>Amount</TableCell>
                    <TableCell>Billing Cycle</TableCell>
                    <TableCell>Next Billing</TableCell>
                    <TableCell>Actions</TableCell>
                  </TableRow>
                </TableHead>
                <TableBody>
                  {subscriptions.map((subscription) => (
                    <TableRow key={subscription.id}>
                      <TableCell>{subscription.companyName}</TableCell>
                      <TableCell>{subscription.planName}</TableCell>
                      <TableCell>
                        <Chip
                          icon={getStatusIcon(subscription.status)}
                          label={subscription.status}
                          color={getStatusColor(subscription.status) as any}
                          size="small"
                        />
                      </TableCell>
                      <TableCell>{formatCurrency(subscription.amount, subscription.currency)}</TableCell>
                      <TableCell>{subscription.billingCycle}</TableCell>
                      <TableCell>{formatDate(subscription.nextBillingDate)}</TableCell>
                      <TableCell>
                        <Tooltip title="View Details">
                          <IconButton size="small">
                            <VisibilityIcon />
                          </IconButton>
                        </Tooltip>
                      </TableCell>
                    </TableRow>
                  ))}
                </TableBody>
              </Table>
            </TableContainer>
          </Box>
        )}
      </Paper>

      {/* Invoice Details Dialog */}
      <Dialog
        open={!!selectedInvoice}
        onClose={() => setSelectedInvoice(null)}
        maxWidth="md"
        fullWidth
      >
        {selectedInvoice && (
          <>
            <DialogTitle>
              Invoice Details - {selectedInvoice.invoiceNumber}
            </DialogTitle>
            <DialogContent>
              <Box sx={{ mb: 2 }}>
                <Typography variant="h6" gutterBottom>Company: {selectedInvoice.companyName}</Typography>
                <Typography variant="body2" color="text.secondary">
                  Issue Date: {formatDate(selectedInvoice.issueDate)} | Due Date: {formatDate(selectedInvoice.dueDate)}
                </Typography>
              </Box>
              <TableContainer>
                <Table>
                  <TableHead>
                    <TableRow>
                      <TableCell>Description</TableCell>
                      <TableCell align="right">Quantity</TableCell>
                      <TableCell align="right">Unit Price</TableCell>
                      <TableCell align="right">Total</TableCell>
                    </TableRow>
                  </TableHead>
                  <TableBody>
                    {selectedInvoice.items.map((item, index) => (
                      <TableRow key={index}>
                        <TableCell>{item.description}</TableCell>
                        <TableCell align="right">{item.quantity}</TableCell>
                        <TableCell align="right">{formatCurrency(item.unitPrice, selectedInvoice.currency)}</TableCell>
                        <TableCell align="right">{formatCurrency(item.total, selectedInvoice.currency)}</TableCell>
                      </TableRow>
                    ))}
                  </TableBody>
                </Table>
              </TableContainer>
              <Box sx={{ mt: 2, textAlign: 'right' }}>
                <Typography variant="h6">
                  Total: {formatCurrency(selectedInvoice.amount, selectedInvoice.currency)}
                </Typography>
              </Box>
            </DialogContent>
            <DialogActions>
              <Button onClick={() => handleDownloadInvoice(selectedInvoice.id, 'pdf')}>
                Download PDF
              </Button>
              <Button onClick={() => handleSendInvoice(selectedInvoice.id)}>
                Send Invoice
              </Button>
              <Button onClick={() => setSelectedInvoice(null)}>Close</Button>
            </DialogActions>
          </>
        )}
      </Dialog>

      {/* Payment Details Dialog */}
      <Dialog
        open={!!selectedPayment}
        onClose={() => setSelectedPayment(null)}
        maxWidth="sm"
        fullWidth
      >
        {selectedPayment && (
          <>
            <DialogTitle>Payment Details</DialogTitle>
            <DialogContent>
              <List>
                <ListItem>
                  <ListItemAvatar>
                    <Avatar>
                      <BusinessIcon />
                    </Avatar>
                  </ListItemAvatar>
                  <ListItemText
                    primary="Company"
                    secondary={selectedPayment.companyName}
                  />
                </ListItem>
                <ListItem>
                  <ListItemAvatar>
                    <Avatar>
                      <MoneyIcon />
                    </Avatar>
                  </ListItemAvatar>
                  <ListItemText
                    primary="Amount"
                    secondary={formatCurrency(selectedPayment.amount, selectedPayment.currency)}
                  />
                </ListItem>
                <ListItem>
                  <ListItemAvatar>
                    <Avatar>
                      {getStatusIcon(selectedPayment.status)}
                    </Avatar>
                  </ListItemAvatar>
                  <ListItemText
                    primary="Status"
                    secondary={
                      <Chip
                        icon={getStatusIcon(selectedPayment.status)}
                        label={selectedPayment.status}
                        color={getStatusColor(selectedPayment.status) as any}
                        size="small"
                      />
                    }
                  />
                </ListItem>
                <ListItem>
                  <ListItemAvatar>
                    <Avatar>
                      <PaymentIcon />
                    </Avatar>
                  </ListItemAvatar>
                  <ListItemText
                    primary="Payment Method"
                    secondary={selectedPayment.paymentMethod}
                  />
                </ListItem>
                <ListItem>
                  <ListItemAvatar>
                    <Avatar>
                      <ReceiptIcon />
                    </Avatar>
                  </ListItemAvatar>
                  <ListItemText
                    primary="Transaction ID"
                    secondary={selectedPayment.transactionId}
                  />
                </ListItem>
                <ListItem>
                  <ListItemAvatar>
                    <Avatar>
                      <InfoIcon />
                    </Avatar>
                  </ListItemAvatar>
                  <ListItemText
                    primary="Description"
                    secondary={selectedPayment.description}
                  />
                </ListItem>
              </List>
            </DialogContent>
            <DialogActions>
              <Button onClick={() => setSelectedPayment(null)}>Close</Button>
            </DialogActions>
          </>
        )}
      </Dialog>
    </Box>
  );
};

export default BillingPage; 