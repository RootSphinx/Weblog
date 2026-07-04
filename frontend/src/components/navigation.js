/**
 * 导航栏组件
 * 处理移动端菜单、搜索等交互
 */

export default () => ({
  // ==================== 状态 ====================
  menuOpen: false,
  windowWidth: window.innerWidth,
  isSearchOpen: false,
  searchQuery: '',

  // ==================== 初始化 ====================
  init() {
    console.log('🧭 Navigation Initialized');

    // 监听窗口大小变化
    window.addEventListener('resize', () => {
      this.windowWidth = window.innerWidth;
      if (window.innerWidth >= 768 && this.menuOpen) {
        this.menuOpen = false;
        document.body.style.overflow = '';
      }
    });

    // 监听HTMX导航事件，自动关闭移动端菜单
    document.body.addEventListener('htmx:beforeRequest', (event) => {
      // 如果是导航链接触发的请求，并且在移动端模式，则关闭菜单
      if (this.windowWidth < 768 && this.menuOpen) {
        console.log('🔗 HTMX navigation detected, closing mobile menu');
        this.closeMobileMenu();
      }
    });
  },

  // ==================== 移动端菜单 ====================
  toggleMenu() {
    this.menuOpen = !this.menuOpen;

    // 移动端防止背景滚动
    if (this.windowWidth < 768) {
      if (this.menuOpen) {
        document.body.style.overflow = 'hidden';
      } else {
        document.body.style.overflow = '';
      }
    }

    console.log('📱 Mobile menu:', this.menuOpen ? 'opened' : 'closed');
  },

  closeMobileMenu() {
    this.menuOpen = false;
    document.body.style.overflow = '';
  },

  // ==================== 搜索功能 ====================
  toggleSearch() {
    this.isSearchOpen = !this.isSearchOpen;

    if (this.isSearchOpen) {
      // 聚焦到搜索框
      this.$nextTick(() => {
        this.$refs.searchInput?.focus();
      });
    }

    console.log('🔍 Search:', this.isSearchOpen ? 'opened' : 'closed');
  },

  submitSearch() {
    if (this.searchQuery.trim()) {
      window.location.href = `/search/?q=${encodeURIComponent(this.searchQuery)}`;
    }
  },

  // ==================== 主题切换 ====================
  toggleTheme() {
    // 委托给 window.themeManager，与 nav.html 模板保持一致
    if (window.themeManager && typeof window.themeManager.toggle === 'function') {
      window.themeManager.toggle();
    } else {
      // 降级：手动切换
      const html = document.documentElement;
      const currentTheme = html.getAttribute('data-theme');
      const newTheme = currentTheme === 'dark' ? 'light' : 'dark';
      if (newTheme === 'dark') {
        html.setAttribute('data-theme', 'dark');
        html.classList.add('dark');
      } else {
        html.removeAttribute('data-theme');
        html.classList.remove('dark');
      }
      localStorage.setItem('dark-mode-enabled', newTheme);
      window.__THEME__ = newTheme;
    }
    console.log('🌓 Theme switched');
  },
});
