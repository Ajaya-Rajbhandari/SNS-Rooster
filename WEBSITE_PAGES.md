# 🌐 Website Pages Setup Guide - SNS Rooster HR

## 📋 **Overview**

This guide provides the structure and content for essential website pages that need to be created for the SNS Rooster HR application.

---

## 🏗️ **Website Structure**

### **Main Pages**
1. **Home Page** - Landing page with app overview
2. **Privacy Policy** - Legal privacy information
3. **Terms of Service** - Legal terms and conditions
4. **Support** - Help and contact information
5. **About Us** - Company information
6. **Features** - Detailed app features
7. **Pricing** - Subscription plans
8. **Contact** - Contact form and information

---

## 📄 **Page 1: Privacy Policy**

### **File: `/privacy-policy.html`**

```html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Privacy Policy - SNS Rooster HR</title>
    <link rel="stylesheet" href="/css/style.css">
</head>
<body>
    <header>
        <nav>
            <div class="logo">SNS Rooster HR</div>
            <ul>
                <li><a href="/">Home</a></li>
                <li><a href="/features">Features</a></li>
                <li><a href="/pricing">Pricing</a></li>
                <li><a href="/support">Support</a></li>
                <li><a href="/about">About</a></li>
            </ul>
        </nav>
    </header>

    <main>
        <section class="hero">
            <h1>Privacy Policy</h1>
            <p>Last updated: [Current Date]</p>
        </section>

        <section class="content">
            <div class="container">
                <!-- Include the full privacy policy content from PRIVACY_POLICY.md -->
                <h2>Introduction</h2>
                <p>SNS Tech Services ("we," "our," or "us") operates the SNS Rooster HR mobile application and web platform...</p>
                
                <h2>Information We Collect</h2>
                <h3>Personal Information</h3>
                <ul>
                    <li>Email address</li>
                    <li>Password (encrypted)</li>
                    <li>First name and last name</li>
                    <li>Company association</li>
                    <li>User role (employee, admin, super admin)</li>
                </ul>
                
                <!-- Continue with all sections from PRIVACY_POLICY.md -->
            </div>
        </section>
    </main>

    <footer>
        <div class="container">
            <div class="footer-content">
                <div class="footer-section">
                    <h3>SNS Rooster HR</h3>
                    <p>Complete employee management solution</p>
                </div>
                <div class="footer-section">
                    <h3>Quick Links</h3>
                    <ul>
                        <li><a href="/privacy-policy">Privacy Policy</a></li>
                        <li><a href="/terms-of-service">Terms of Service</a></li>
                        <li><a href="/support">Support</a></li>
                    </ul>
                </div>
                <div class="footer-section">
                    <h3>Contact</h3>
                    <p>Email: support@snstechservices.com.au</p>
                    <p>Privacy: privacy@snstechservices.com.au</p>
                </div>
            </div>
            <div class="footer-bottom">
                <p>&copy; 2024 SNS Tech Services. All rights reserved.</p>
            </div>
        </div>
    </footer>
</body>
</html>
```

---

## 📄 **Page 2: Terms of Service**

### **File: `/terms-of-service.html`**

```html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Terms of Service - SNS Rooster HR</title>
    <link rel="stylesheet" href="/css/style.css">
</head>
<body>
    <header>
        <!-- Same navigation as privacy policy -->
    </header>

    <main>
        <section class="hero">
            <h1>Terms of Service</h1>
            <p>Last updated: [Current Date]</p>
        </section>

        <section class="content">
            <div class="container">
                <!-- Include the full terms of service content from TERMS_OF_SERVICE.md -->
                <h2>Introduction</h2>
                <p>These Terms of Service ("Terms") govern your use of the SNS Rooster HR mobile application and web platform...</p>
                
                <h2>Acceptance of Terms</h2>
                <p>By accessing or using SNS Rooster HR, you agree to be bound by these Terms...</p>
                
                <!-- Continue with all sections from TERMS_OF_SERVICE.md -->
            </div>
        </section>
    </main>

    <footer>
        <!-- Same footer as privacy policy -->
    </footer>
</body>
</html>
```

---

## 📄 **Page 3: Support Page**

### **File: `/support.html`**

```html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Support - SNS Rooster HR</title>
    <link rel="stylesheet" href="/css/style.css">
</head>
<body>
    <header>
        <!-- Same navigation -->
    </header>

    <main>
        <section class="hero">
            <h1>Support & Help Center</h1>
            <p>Get help with SNS Rooster HR</p>
        </section>

        <section class="content">
            <div class="container">
                <div class="support-grid">
                    <div class="support-card">
                        <h3>📱 App Installation</h3>
                        <p>Learn how to install the Android app on your device.</p>
                        <a href="#installation" class="btn">View Guide</a>
                    </div>
                    
                    <div class="support-card">
                        <h3>🔐 Account Setup</h3>
                        <p>Set up your account and get started with the app.</p>
                        <a href="#account-setup" class="btn">View Guide</a>
                    </div>
                    
                    <div class="support-card">
                        <h3>📍 Location Services</h3>
                        <p>Configure location permissions for attendance tracking.</p>
                        <a href="#location" class="btn">View Guide</a>
                    </div>
                    
                    <div class="support-card">
                        <h3>📊 Using the Dashboard</h3>
                        <p>Navigate and use the main dashboard features.</p>
                        <a href="#dashboard" class="btn">View Guide</a>
                    </div>
                </div>

                <div class="contact-section">
                    <h2>Contact Support</h2>
                    <div class="contact-methods">
                        <div class="contact-method">
                            <h3>📧 Email Support</h3>
                            <p>support@snstechservices.com.au</p>
                            <p>Response time: Within 24 hours</p>
                        </div>
                        
                        <div class="contact-method">
                            <h3>🔒 Privacy Inquiries</h3>
                            <p>privacy@snstechservices.com.au</p>
                            <p>For privacy and data concerns</p>
                        </div>
                        
                        <div class="contact-method">
                            <h3>💼 Business Inquiries</h3>
                            <p>business@snstechservices.com.au</p>
                            <p>For partnership and enterprise solutions</p>
                        </div>
                    </div>
                </div>

                <div class="faq-section">
                    <h2>Frequently Asked Questions</h2>
                    <div class="faq-item">
                        <h3>How do I install the Android app?</h3>
                        <p>Download the APK from our website or use the download link in the web app. Enable "Install from unknown sources" in your Android settings.</p>
                    </div>
                    
                    <div class="faq-item">
                        <h3>Why can't I check in?</h3>
                        <p>Make sure you have location permissions enabled and are within the designated geofence area. Check your internet connection.</p>
                    </div>
                    
                    <div class="faq-item">
                        <h3>How do I reset my password?</h3>
                        <p>Use the "Forgot Password" option on the login screen. You'll receive a reset link via email.</p>
                    </div>
                    
                    <div class="faq-item">
                        <h3>Is my data secure?</h3>
                        <p>Yes, we use industry-standard encryption and security measures. See our Privacy Policy for details.</p>
                    </div>
                </div>
            </div>
        </section>
    </main>

    <footer>
        <!-- Same footer -->
    </footer>
</body>
</html>
```

---

## 📄 **Page 4: About Us**

### **File: `/about.html`**

```html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>About Us - SNS Rooster HR</title>
    <link rel="stylesheet" href="/css/style.css">
</head>
<body>
    <header>
        <!-- Same navigation -->
    </header>

    <main>
        <section class="hero">
            <h1>About SNS Tech Services</h1>
            <p>Empowering businesses with innovative HR solutions</p>
        </section>

        <section class="content">
            <div class="container">
                <div class="about-section">
                    <h2>Our Mission</h2>
                    <p>At SNS Tech Services, we believe that every business deserves access to professional HR management tools. Our mission is to simplify employee management through innovative technology solutions that save time, reduce costs, and improve workplace efficiency.</p>
                </div>

                <div class="about-section">
                    <h2>What We Do</h2>
                    <p>SNS Rooster HR is our flagship product - a comprehensive employee management system designed for modern businesses. We provide:</p>
                    <ul>
                        <li>Attendance tracking with GPS location</li>
                        <li>Payroll management and processing</li>
                        <li>Leave management and approval</li>
                        <li>Employee self-service portal</li>
                        <li>Analytics and reporting</li>
                        <li>Real-time notifications</li>
                    </ul>
                </div>

                <div class="about-section">
                    <h2>Why Choose SNS Rooster HR?</h2>
                    <div class="features-grid">
                        <div class="feature">
                            <h3>🚀 Easy to Use</h3>
                            <p>Intuitive interface designed for all skill levels</p>
                        </div>
                        <div class="feature">
                            <h3>🔒 Secure</h3>
                            <p>Enterprise-grade security and data protection</p>
                        </div>
                        <div class="feature">
                            <h3>📱 Mobile-First</h3>
                            <p>Optimized for mobile devices and remote work</p>
                        </div>
                        <div class="feature">
                            <h3>💰 Cost-Effective</h3>
                            <p>Affordable pricing for businesses of all sizes</p>
                        </div>
                    </div>
                </div>

                <div class="about-section">
                    <h2>Contact Information</h2>
                    <div class="contact-info">
                        <p><strong>Email:</strong> info@snstechservices.com.au</p>
                        <p><strong>Support:</strong> support@snstechservices.com.au</p>
                        <p><strong>Privacy:</strong> privacy@snstechservices.com.au</p>
                        <p><strong>Business:</strong> business@snstechservices.com.au</p>
                    </div>
                </div>
            </div>
        </section>
    </main>

    <footer>
        <!-- Same footer -->
    </footer>
</body>
</html>
```

---

## 🎨 **CSS Styling**

### **File: `/css/style.css`**

```css
/* Reset and base styles */
* {
    margin: 0;
    padding: 0;
    box-sizing: border-box;
}

body {
    font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
    line-height: 1.6;
    color: #333;
}

.container {
    max-width: 1200px;
    margin: 0 auto;
    padding: 0 20px;
}

/* Header */
header {
    background: #fff;
    box-shadow: 0 2px 5px rgba(0,0,0,0.1);
    position: sticky;
    top: 0;
    z-index: 100;
}

nav {
    display: flex;
    justify-content: space-between;
    align-items: center;
    padding: 1rem 2rem;
}

.logo {
    font-size: 1.5rem;
    font-weight: bold;
    color: #2563eb;
}

nav ul {
    display: flex;
    list-style: none;
    gap: 2rem;
}

nav a {
    text-decoration: none;
    color: #333;
    font-weight: 500;
    transition: color 0.3s;
}

nav a:hover {
    color: #2563eb;
}

/* Hero section */
.hero {
    background: linear-gradient(135deg, #2563eb, #1d4ed8);
    color: white;
    text-align: center;
    padding: 4rem 2rem;
}

.hero h1 {
    font-size: 3rem;
    margin-bottom: 1rem;
}

.hero p {
    font-size: 1.2rem;
    opacity: 0.9;
}

/* Content sections */
.content {
    padding: 4rem 0;
}

.content h2 {
    color: #1f2937;
    margin-bottom: 1.5rem;
    font-size: 2rem;
}

.content h3 {
    color: #374151;
    margin-bottom: 1rem;
    font-size: 1.5rem;
}

.content p {
    margin-bottom: 1rem;
    color: #6b7280;
}

.content ul {
    margin-left: 2rem;
    margin-bottom: 1rem;
}

.content li {
    margin-bottom: 0.5rem;
    color: #6b7280;
}

/* Support grid */
.support-grid {
    display: grid;
    grid-template-columns: repeat(auto-fit, minmax(300px, 1fr));
    gap: 2rem;
    margin-bottom: 4rem;
}

.support-card {
    background: #f9fafb;
    padding: 2rem;
    border-radius: 8px;
    border: 1px solid #e5e7eb;
    text-align: center;
}

.support-card h3 {
    color: #1f2937;
    margin-bottom: 1rem;
}

.btn {
    display: inline-block;
    background: #2563eb;
    color: white;
    padding: 0.75rem 1.5rem;
    text-decoration: none;
    border-radius: 6px;
    font-weight: 500;
    transition: background 0.3s;
}

.btn:hover {
    background: #1d4ed8;
}

/* Contact methods */
.contact-methods {
    display: grid;
    grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
    gap: 2rem;
    margin-bottom: 4rem;
}

.contact-method {
    background: #f9fafb;
    padding: 2rem;
    border-radius: 8px;
    border: 1px solid #e5e7eb;
    text-align: center;
}

.contact-method h3 {
    color: #1f2937;
    margin-bottom: 1rem;
}

/* FAQ */
.faq-item {
    background: #f9fafb;
    padding: 2rem;
    border-radius: 8px;
    margin-bottom: 1rem;
    border: 1px solid #e5e7eb;
}

.faq-item h3 {
    color: #1f2937;
    margin-bottom: 1rem;
}

/* Features grid */
.features-grid {
    display: grid;
    grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
    gap: 2rem;
    margin-bottom: 2rem;
}

.feature {
    background: #f9fafb;
    padding: 2rem;
    border-radius: 8px;
    border: 1px solid #e5e7eb;
    text-align: center;
}

.feature h3 {
    color: #1f2937;
    margin-bottom: 1rem;
}

/* Footer */
footer {
    background: #1f2937;
    color: white;
    padding: 3rem 0 1rem;
}

.footer-content {
    display: grid;
    grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
    gap: 2rem;
    margin-bottom: 2rem;
}

.footer-section h3 {
    margin-bottom: 1rem;
    color: #f9fafb;
}

.footer-section ul {
    list-style: none;
}

.footer-section a {
    color: #d1d5db;
    text-decoration: none;
    transition: color 0.3s;
}

.footer-section a:hover {
    color: white;
}

.footer-bottom {
    border-top: 1px solid #374151;
    padding-top: 1rem;
    text-align: center;
    color: #9ca3af;
}

/* Responsive design */
@media (max-width: 768px) {
    nav {
        flex-direction: column;
        gap: 1rem;
    }
    
    nav ul {
        flex-wrap: wrap;
        justify-content: center;
    }
    
    .hero h1 {
        font-size: 2rem;
    }
    
    .support-grid,
    .contact-methods,
    .features-grid {
        grid-template-columns: 1fr;
    }
}
```

---

## 📋 **Implementation Checklist**

### **✅ Website Setup Tasks**
- [ ] **Create website directory structure**
- [ ] **Set up hosting (Firebase Hosting, Netlify, or similar)**
- [ ] **Create HTML pages (privacy-policy.html, terms-of-service.html, support.html, about.html)**
- [ ] **Create CSS styling file**
- [ ] **Add navigation and footer to all pages**
- [ ] **Include content from existing markdown files**
- [ ] **Test responsive design**
- [ ] **Set up custom domain (optional)**
- [ ] **Configure SEO meta tags**
- [ ] **Add Google Analytics (optional)**

### **✅ Content Integration**
- [ ] **Copy privacy policy content from PRIVACY_POLICY.md**
- [ ] **Copy terms of service content from TERMS_OF_SERVICE.md**
- [ ] **Create FAQ content for support page**
- [ ] **Write about us content**
- [ ] **Add contact information**
- [ ] **Include download links for Android app**

### **✅ Testing**
- [ ] **Test all pages on desktop**
- [ ] **Test all pages on mobile**
- [ ] **Verify all links work**
- [ ] **Check contact forms (if any)**
- [ ] **Test download links**
- [ ] **Validate HTML and CSS**

---

## 🚀 **Next Steps**

1. **Choose hosting platform** (Firebase Hosting recommended for consistency)
2. **Create the HTML files** with the provided structure
3. **Add the CSS styling**
4. **Integrate content** from existing markdown files
5. **Test and deploy**
6. **Update app links** to point to the new website pages

The website pages will provide a professional online presence for SNS Rooster HR and serve as a central hub for legal information, support, and company details. 