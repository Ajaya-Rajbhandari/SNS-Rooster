const { Storage } = require('@google-cloud/storage');
const storage = new Storage({ keyFilename: 'serviceAccountKey.json', projectId: 'sns-rooster-8cca5' });

storage.getBuckets().then(results => {
  const buckets = results[0];
  console.log('Buckets:');
  buckets.forEach(bucket => {
    console.log(bucket.name);
  });
}).catch(err => {
  console.error('Error listing buckets:', err);
});
