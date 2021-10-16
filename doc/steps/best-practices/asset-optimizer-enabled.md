> [Home][home] ▸ [Docs][docs] ▸ **Asset Optimizer enabled**
# Asset Optimizer enabled


This step was created based on [**Sitecore Experience Accelerator best practices**][sc_doc] article.

### How to solve

* Per site - if you want to enable to for a single site
    - Navigate to **Site→Presentation→Page Designs**
    - Set **Styles Optimizing Enabled** to **Yes**
    - Set **Scripts Optimizing Enabled** to **Yes**

* Per instance - if you want to enable it for every site
    - Navigate to `/sitecore/system/Settings/Foundation/Experience Accelerator/Theming/Optimiser/Scripts`
    - Set **Mode** to **Concatenate and Minify**
    - Navigate to `/sitecore/system/Settings/Foundation/Experience Accelerator/Theming/Optimiser/Scripts`
    - Set **Mode** to **Concatenate and Minify**

### Links:
- [SXA Best practices][sc_doc_bp]
- [Verify that you have enabled the Asset Optimizer][sc_doc]
- [Enable and configure the Asset Optimizer](https://doc.sitecore.com/developers/sxa/18/sitecore-experience-accelerator/en/enable-and-configure-the-asset-optimizer.html)

[home]: /README.md
[docs]: /doc/README.md
[sc_doc_bp]: https://doc.sitecore.com/developers/sxa/18/sitecore-experience-accelerator/en/best-practices.html
[sc_doc]: https://doc.sitecore.com/developers/sxa/18/sitecore-experience-accelerator/en/recommendations--enhancing-sxa-performance.html#UUID-900ac908-4caf-dd24-f6b4-a00297c4c20f_section-idm46485168400096_body
