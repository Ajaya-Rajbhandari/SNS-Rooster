#!/usr/bin/env node

/**
 * Memory Monitor Script
 * Monitors memory usage and identifies potential memory leaks
 */

const fs = require('fs');
const path = require('path');

class MemoryMonitor {
  constructor() {
    this.memoryLog = [];
    this.startTime = Date.now();
    this.interval = null;
  }

  start(intervalMs = 30000) { // Check every 30 seconds
    console.log('🔍 Starting memory monitor...');
    console.log(`📊 Monitoring interval: ${intervalMs / 1000} seconds`);
    
    this.interval = setInterval(() => {
      this.checkMemory();
    }, intervalMs);
    
    // Initial check
    this.checkMemory();
  }

  stop() {
    if (this.interval) {
      clearInterval(this.interval);
      this.interval = null;
      console.log('🛑 Memory monitor stopped');
    }
  }

  checkMemory() {
    const memoryUsage = process.memoryUsage();
    const timestamp = new Date().toISOString();
    
    const memoryData = {
      timestamp,
      uptime: process.uptime(),
      memory: {
        rss: Math.round(memoryUsage.rss / 1024 / 1024), // MB
        heapUsed: Math.round(memoryUsage.heapUsed / 1024 / 1024), // MB
        heapTotal: Math.round(memoryUsage.heapTotal / 1024 / 1024), // MB
        external: Math.round(memoryUsage.external / 1024 / 1024), // MB
        arrayBuffers: Math.round(memoryUsage.arrayBuffers / 1024 / 1024) // MB
      }
    };

    this.memoryLog.push(memoryData);
    
    // Keep only last 100 entries
    if (this.memoryLog.length > 100) {
      this.memoryLog = this.memoryLog.slice(-100);
    }

    // Log current memory usage
    console.log(`\n📈 Memory Usage (${timestamp}):`);
    console.log(`   RSS: ${memoryData.memory.rss} MB`);
    console.log(`   Heap Used: ${memoryData.memory.heapUsed} MB`);
    console.log(`   Heap Total: ${memoryData.memory.heapTotal} MB`);
    console.log(`   External: ${memoryData.memory.external} MB`);
    console.log(`   Array Buffers: ${memoryData.memory.arrayBuffers} MB`);

    // Check for memory warnings
    this.checkMemoryWarnings(memoryData);
    
    // Analyze memory trends
    this.analyzeMemoryTrends();
  }

  checkMemoryWarnings(memoryData) {
    const { heapUsed, heapTotal, external } = memoryData.memory;
    
    // Warning thresholds
    if (heapUsed > 400) {
      console.warn(`⚠️  WARNING: High heap usage: ${heapUsed} MB`);
    }
    
    if (heapTotal > 500) {
      console.warn(`⚠️  WARNING: High heap total: ${heapTotal} MB`);
    }
    
    if (external > 100) {
      console.warn(`⚠️  WARNING: High external memory: ${external} MB`);
    }
    
    if (heapUsed > 600) {
      console.error(`🚨 CRITICAL: Very high heap usage: ${heapUsed} MB`);
    }
  }

  analyzeMemoryTrends() {
    if (this.memoryLog.length < 3) return;
    
    const recent = this.memoryLog.slice(-3);
    const first = recent[0].memory.heapUsed;
    const last = recent[recent.length - 1].memory.heapUsed;
    const increase = last - first;
    
    if (increase > 50) {
      console.warn(`📈 MEMORY LEAK DETECTED: Heap increased by ${increase} MB in last ${recent.length} checks`);
    }
    
    if (increase < -20) {
      console.log(`📉 Memory cleanup detected: Heap decreased by ${Math.abs(increase)} MB`);
    }
  }

  generateReport() {
    if (this.memoryLog.length === 0) {
      console.log('No memory data available');
      return;
    }

    const report = {
      startTime: this.startTime,
      endTime: Date.now(),
      duration: Date.now() - this.startTime,
      totalChecks: this.memoryLog.length,
      memoryStats: this.calculateMemoryStats(),
      recommendations: this.generateRecommendations()
    };

    console.log('\n📊 Memory Monitor Report:');
    console.log('========================');
    console.log(`Duration: ${Math.round(report.duration / 1000 / 60)} minutes`);
    console.log(`Total checks: ${report.totalChecks}`);
    console.log('\nMemory Statistics:');
    console.log(`  Average Heap Used: ${report.memoryStats.avgHeapUsed} MB`);
    console.log(`  Peak Heap Used: ${report.memoryStats.peakHeapUsed} MB`);
    console.log(`  Average RSS: ${report.memoryStats.avgRss} MB`);
    console.log(`  Peak RSS: ${report.memoryStats.peakRss} MB`);
    
    console.log('\nRecommendations:');
    report.recommendations.forEach((rec, index) => {
      console.log(`  ${index + 1}. ${rec}`);
    });

    // Save report to file
    const reportPath = path.join(__dirname, '../logs/memory-report.json');
    fs.mkdirSync(path.dirname(reportPath), { recursive: true });
    fs.writeFileSync(reportPath, JSON.stringify(report, null, 2));
    console.log(`\n📄 Report saved to: ${reportPath}`);
  }

  calculateMemoryStats() {
    const heapUsed = this.memoryLog.map(log => log.memory.heapUsed);
    const rss = this.memoryLog.map(log => log.memory.rss);
    
    return {
      avgHeapUsed: Math.round(heapUsed.reduce((a, b) => a + b, 0) / heapUsed.length),
      peakHeapUsed: Math.max(...heapUsed),
      avgRss: Math.round(rss.reduce((a, b) => a + b, 0) / rss.length),
      peakRss: Math.max(...rss)
    };
  }

  generateRecommendations() {
    const recommendations = [];
    const stats = this.calculateMemoryStats();
    
    if (stats.peakHeapUsed > 500) {
      recommendations.push('Consider implementing response size limits for large data exports');
    }
    
    if (stats.avgHeapUsed > 300) {
      recommendations.push('Review database queries and implement pagination for large datasets');
    }
    
    if (stats.peakRss > 800) {
      recommendations.push('Monitor for memory leaks in file uploads and data processing');
    }
    
    if (this.memoryLog.length > 10) {
      const recent = this.memoryLog.slice(-10);
      const first = recent[0].memory.heapUsed;
      const last = recent[recent.length - 1].memory.heapUsed;
      
      if (last - first > 100) {
        recommendations.push('Investigate potential memory leaks in recent operations');
      }
    }
    
    if (recommendations.length === 0) {
      recommendations.push('Memory usage appears normal - continue monitoring');
    }
    
    return recommendations;
  }
}

// CLI interface
if (require.main === module) {
  const monitor = new MemoryMonitor();
  
  // Handle graceful shutdown
  process.on('SIGINT', () => {
    console.log('\n🛑 Shutting down memory monitor...');
    monitor.stop();
    monitor.generateReport();
    process.exit(0);
  });
  
  process.on('SIGTERM', () => {
    console.log('\n🛑 Shutting down memory monitor...');
    monitor.stop();
    monitor.generateReport();
    process.exit(0);
  });
  
  // Start monitoring
  const interval = process.argv[2] ? parseInt(process.argv[2]) * 1000 : 30000;
  monitor.start(interval);
  
  console.log('Press Ctrl+C to stop monitoring and generate report');
}

module.exports = MemoryMonitor; 