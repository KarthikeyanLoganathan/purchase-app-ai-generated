const webSecurity = {
    /**
     * Validate secret code from request
     */
    validateSecretCode(providedCode) {
        const storedCode = config.getConfigValue("APP_CODE");

        if (!storedCode || storedCode === "CHANGE_ME_" + new Date().getTime()) {
            throw new Error("APP_CODE not configured in config sheet");
        }

        if (providedCode !== storedCode) {
            throw new Error("Invalid secret code");
        }

        return true;
    }
};