const request = require("supertest");
const mongoose = require("mongoose");
const app = require('../app');
const User = require("../models/User");
const path = require("path");

console.log('APP TYPE:', typeof app, app && app.constructor && app.constructor.name);

describe("Document Upload API", () => {
  let userId;
  let token;

  beforeAll(async () => {
    // Create a test user
    const user = new User({
      firstName: "Doc",
      lastName: "Tester",
      email: `docuser${Date.now()}@example.com`,
      password: "password123",
    });
    const savedUser = await user.save();
    userId = savedUser._id;
    // Optionally, generate a JWT token if your API requires authentication
    // token = ...
  });

  afterAll(async () => {
    await User.deleteMany({ email: /docuser/ });
    await mongoose.connection.close();
  });

  it("should upload and save an ID card document", async () => {
    const res = await request(app)
      .post("/api/auth/users/profile/document")
      .set("Content-Type", "multipart/form-data")
      .field("documentType", "idCard")
      .attach("document", path.join(__dirname, "fixtures", "test-idcard.pdf"));
    console.log(res.body);
    expect(res.statusCode).toBe(200);
    expect(res.body.documentInfo.fileName).toBe("test-idcard.pdf");
    expect(res.body.documentInfo.filePath).toContain(
      "uploads/documents"
    );
  });
});
