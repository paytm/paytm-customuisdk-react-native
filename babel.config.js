const MODULE_RESOLVER = [
  'module-resolver',
  {
    extensions: ['.js', '.ts','.tsx', '.ios.js', '.ios.ts', '.android.js', '.android.ts', '.json'],
    alias: {
      '@Components': './App/Components',
      '@Navigation': './App/Navigation',
      '@Constants': './App/Constants',
      '@Features': './App/Features',
      '@Services': './App/Services',
      '@Fixtures': './App/Fixtures',
      '@Themes': './App/Themes',
      '@Config': './App/Config',
      '@Sagas': './App/Sagas',
      '@Redux': './App/Redux',
      '@Types': './App/Types',
      '@I18n': './App/I18n',
      '@Lib': './App/Lib',
    },
  },
];
module.exports = {
  plugins: [MODULE_RESOLVER],
  presets: ['module:metro-react-native-babel-preset'],
  env: {
    production: {
      plugins: ['ignite-ignore-reactotron', MODULE_RESOLVER],
    },
  },
};
