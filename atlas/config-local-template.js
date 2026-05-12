define([], function () {
    var configLocal = {};

    // WebAPI - explicit cross-origin URL substituted by envsubst at startup.
    // Upstream Broadsea uses window.location here; we override because Atlas
    // and WebAPI live on different host ports in this setup.
    configLocal.webAPIRoot = '$WEBAPI_URL';
    configLocal.api = {
        name: "$ATLAS_INSTANCE_NAME",
        url: '$WEBAPI_URL'
    };

    configLocal.userAuthenticationEnabled = false;
    configLocal.plpResultsEnabled = false;
    configLocal.useExecutionEngine = false;
    configLocal.cohortComparisonResultsEnabled = false;
    configLocal.disableBrowserCheck = false;
    configLocal.enableTaggingSection = false;
    configLocal.cacheSources = false;
    configLocal.pollInterval = 60000;
    configLocal.enableSkipLogin = false;
    configLocal.viewProfileDates = false;
    configLocal.enableCosts = false;
    configLocal.showCompanyInfo = true;
    configLocal.defaultLocale = "en";
    configLocal.enablePersonCount = true;
    configLocal.enableTermsAndConditions = true;

    return configLocal;
});
