module.exports = {
  content: [
    "./web/**/*.jsp",           // ✅ nếu bạn dùng JSP
    "./web/**/*.html",          // hoặc HTML
    "./src/**/*.js",            // nếu có JS chứa class
  ],
  theme: { extend: {} },
  plugins: [],
}
