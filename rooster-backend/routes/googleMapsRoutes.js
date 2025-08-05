const express = require('express');
const router = express.Router();
const axios = require('axios');

/**
 * @route GET /api/google-maps/script
 * @desc Serve Google Maps JavaScript with API key (server-side proxy)
 * @access Public
 */
router.get('/google-maps/script', async (req, res) => {
  try {
    const apiKey = process.env.GOOGLE_MAPS_API_KEY;
    if (!apiKey) {
      return res.status(500).json({ 
        error: 'Google Maps API key not configured' 
      });
    }

    // Fetch the Google Maps JavaScript from Google's servers
    const response = await axios.get(
      `https://maps.googleapis.com/maps/api/js`,
      {
        params: {
          key: apiKey,
          libraries: 'places',
          callback: 'initMap',
          loading: 'async'
        },
        responseType: 'text'
      }
    );

    // Set appropriate headers for JavaScript
    res.setHeader('Content-Type', 'application/javascript');
    res.setHeader('Cache-Control', 'public, max-age=3600'); // Cache for 1 hour
    res.send(response.data);
  } catch (error) {
    console.error('Google Maps script proxy error:', error.message);
    res.status(500).json({ 
      error: 'Failed to load Google Maps script',
      details: error.message 
    });
  }
});

/**
 * @route GET /api/maps/geocode
 * @desc Geocode an address using Google Maps API (server-side proxy)
 * @access Private
 */
router.get('/geocode', async (req, res) => {
  try {
    const { address } = req.query;
    
    if (!address) {
      return res.status(400).json({ 
        error: 'Address parameter is required' 
      });
    }

    const apiKey = process.env.GOOGLE_MAPS_API_KEY;
    if (!apiKey) {
      return res.status(500).json({ 
        error: 'Google Maps API key not configured' 
      });
    }

    const response = await axios.get(
      `https://maps.googleapis.com/maps/api/geocode/json`,
      {
        params: {
          address: address,
          key: apiKey
        }
      }
    );

    res.json(response.data);
  } catch (error) {
    console.error('Geocoding error:', error.message);
    res.status(500).json({ 
      error: 'Failed to geocode address',
      details: error.message 
    });
  }
});

/**
 * @route GET /api/maps/places
 * @desc Search for places using Google Places API (server-side proxy)
 * @access Private
 */
router.get('/places', async (req, res) => {
  try {
    const { input, location, radius } = req.query;
    
    if (!input) {
      return res.status(400).json({ 
        error: 'Input parameter is required' 
      });
    }

    const apiKey = process.env.GOOGLE_MAPS_API_KEY;
    if (!apiKey) {
      return res.status(500).json({ 
        error: 'Google Maps API key not configured' 
      });
    }

    const params = {
      input: input,
      key: apiKey,
      types: 'establishment'
    };

    if (location) {
      params.location = location;
    }

    if (radius) {
      params.radius = radius;
    }

    const response = await axios.get(
      `https://maps.googleapis.com/maps/api/place/autocomplete/json`,
      { params }
    );

    res.json(response.data);
  } catch (error) {
    console.error('Places API error:', error.message);
    res.status(500).json({ 
      error: 'Failed to search places',
      details: error.message 
    });
  }
});

/**
 * @route GET /api/maps/distance
 * @desc Calculate distance between two points using Google Distance Matrix API
 * @access Private
 */
router.get('/distance', async (req, res) => {
  try {
    const { origins, destinations, mode = 'driving' } = req.query;
    
    if (!origins || !destinations) {
      return res.status(400).json({ 
        error: 'Origins and destinations parameters are required' 
      });
    }

    const apiKey = process.env.GOOGLE_MAPS_API_KEY;
    if (!apiKey) {
      return res.status(500).json({ 
        error: 'Google Maps API key not configured' 
      });
    }

    const response = await axios.get(
      `https://maps.googleapis.com/maps/api/distancematrix/json`,
      {
        params: {
          origins: origins,
          destinations: destinations,
          mode: mode,
          key: apiKey
        }
      }
    );

    res.json(response.data);
  } catch (error) {
    console.error('Distance Matrix API error:', error.message);
    res.status(500).json({ 
      error: 'Failed to calculate distance',
      details: error.message 
    });
  }
});

/**
 * @route GET /api/maps/config
 * @desc Get Google Maps configuration (without exposing API key)
 * @access Public
 */
router.get('/config', (req, res) => {
  try {
    // Return configuration without exposing the API key
    res.json({
      libraries: ['places'],
      version: 'weekly',
      // Don't include the API key here - it will be handled server-side
      message: 'Use server-side endpoints for Google Maps operations'
    });
  } catch (error) {
    console.error('Config error:', error.message);
    res.status(500).json({ 
      error: 'Failed to get configuration' 
    });
  }
});

/**
 * @route GET /api/config/firebase
 * @desc Get Firebase configuration securely
 * @access Public
 */
router.get('/firebase', (req, res) => {
  try {
    const firebaseApiKey = process.env.FIREBASE_API_KEY || process.env.GOOGLE_MAPS_API_KEY;
    
    if (!firebaseApiKey) {
      return res.status(500).json({ 
        error: 'Firebase API key not configured' 
      });
    }

    // Return Firebase configuration with API key
    res.json({
      apiKey: firebaseApiKey,
      authDomain: "sns-rooster-8cca5.firebaseapp.com",
      projectId: "sns-rooster-8cca5",
      storageBucket: "sns-rooster-8cca5.appspot.com",
      messagingSenderId: "901502276055",
      appId: "1:901502276055:web:f4f94088120f52dc8f7b92",
      measurementId: "G-7QJ3X926H8"
    });
  } catch (error) {
    console.error('Firebase config error:', error.message);
    res.status(500).json({ 
      error: 'Failed to get Firebase configuration' 
    });
  }
});

module.exports = router; 