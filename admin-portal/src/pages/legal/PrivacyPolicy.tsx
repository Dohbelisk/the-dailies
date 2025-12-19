import { Link } from 'react-router-dom'
import { Puzzle, ArrowLeft } from 'lucide-react'

export default function PrivacyPolicy() {
  const lastUpdated = 'December 20, 2024'
  const contactEmail = 'support@dbkgames.co.za'

  return (
    <div className="min-h-screen bg-gray-50 dark:bg-gray-900">
      {/* Header */}
      <header className="bg-white dark:bg-gray-800 shadow-sm">
        <div className="max-w-4xl mx-auto px-4 py-4 flex items-center gap-4">
          <Link to="/" className="text-gray-500 hover:text-gray-700 dark:text-gray-400 dark:hover:text-gray-200">
            <ArrowLeft className="w-5 h-5" />
          </Link>
          <div className="flex items-center gap-3">
            <div className="w-10 h-10 bg-primary-600 rounded-xl flex items-center justify-center">
              <Puzzle className="w-6 h-6 text-white" />
            </div>
            <div>
              <h1 className="text-xl font-bold text-gray-900 dark:text-white">The Dailies</h1>
              <p className="text-xs text-gray-500 dark:text-gray-400">Privacy Policy</p>
            </div>
          </div>
        </div>
      </header>

      {/* Content */}
      <main className="max-w-4xl mx-auto px-4 py-8">
        <div className="bg-white dark:bg-gray-800 rounded-2xl shadow-sm p-8">
          <h1 className="text-3xl font-bold text-gray-900 dark:text-white mb-2">Privacy Policy</h1>
          <p className="text-sm text-gray-500 dark:text-gray-400 mb-8">Last updated: {lastUpdated}</p>

          <div className="prose dark:prose-invert max-w-none">
            <section className="mb-8">
              <h2 className="text-xl font-semibold text-gray-900 dark:text-white mb-4">1. Introduction</h2>
              <p className="text-gray-600 dark:text-gray-300 mb-4">
                Welcome to The Dailies ("we," "our," or "us"). This Privacy Policy explains how we collect, use,
                disclose, and safeguard your information when you use our mobile application The Dailies
                (the "App"). Please read this Privacy Policy carefully.
              </p>
              <p className="text-gray-600 dark:text-gray-300">
                By using the App, you agree to the collection and use of information in accordance with this policy.
              </p>
            </section>

            <section className="mb-8">
              <h2 className="text-xl font-semibold text-gray-900 dark:text-white mb-4">2. Information We Collect</h2>

              <h3 className="text-lg font-medium text-gray-800 dark:text-gray-200 mb-2">2.1 Information You Provide</h3>
              <ul className="list-disc pl-6 text-gray-600 dark:text-gray-300 mb-4 space-y-2">
                <li><strong>Account Information:</strong> If you create an account, we collect your email address and username.</li>
                <li><strong>Game Progress:</strong> Your puzzle completion times, scores, and statistics.</li>
                <li><strong>Feedback:</strong> Any feedback or support requests you submit through the App.</li>
              </ul>

              <h3 className="text-lg font-medium text-gray-800 dark:text-gray-200 mb-2">2.2 Automatically Collected Information</h3>
              <ul className="list-disc pl-6 text-gray-600 dark:text-gray-300 mb-4 space-y-2">
                <li><strong>Device Information:</strong> Device type, operating system version, unique device identifiers.</li>
                <li><strong>Usage Data:</strong> How you interact with the App, features used, and time spent.</li>
                <li><strong>Crash Reports:</strong> Technical information when the App crashes to help us improve stability.</li>
              </ul>

              <h3 className="text-lg font-medium text-gray-800 dark:text-gray-200 mb-2">2.3 Third-Party Services</h3>
              <p className="text-gray-600 dark:text-gray-300">Our App uses the following third-party services that may collect information:</p>
              <ul className="list-disc pl-6 text-gray-600 dark:text-gray-300 mt-2 space-y-2">
                <li><strong>Google AdMob:</strong> To display advertisements. AdMob may collect device identifiers and usage data for ad personalization.</li>
                <li><strong>Firebase Analytics:</strong> To understand App usage patterns and improve user experience.</li>
                <li><strong>Firebase Crashlytics:</strong> To collect crash reports and diagnostic information.</li>
                <li><strong>Google Play Billing:</strong> To process in-app purchases and subscriptions.</li>
              </ul>
            </section>

            <section className="mb-8">
              <h2 className="text-xl font-semibold text-gray-900 dark:text-white mb-4">3. How We Use Your Information</h2>
              <p className="text-gray-600 dark:text-gray-300 mb-2">We use the collected information to:</p>
              <ul className="list-disc pl-6 text-gray-600 dark:text-gray-300 space-y-2">
                <li>Provide and maintain the App's functionality</li>
                <li>Save and sync your game progress</li>
                <li>Process your subscriptions and purchases</li>
                <li>Display advertisements (for free users)</li>
                <li>Analyze usage to improve the App</li>
                <li>Send you updates and notifications (with your consent)</li>
                <li>Respond to your support requests</li>
                <li>Detect and prevent fraud or abuse</li>
              </ul>
            </section>

            <section className="mb-8">
              <h2 className="text-xl font-semibold text-gray-900 dark:text-white mb-4">4. Advertising</h2>
              <p className="text-gray-600 dark:text-gray-300 mb-4">
                The free version of our App displays advertisements provided by Google AdMob. These ads may be
                personalized based on your interests, which are determined by your activity across other apps
                and websites.
              </p>
              <p className="text-gray-600 dark:text-gray-300 mb-4">
                You can opt out of personalized advertising by adjusting your device settings:
              </p>
              <ul className="list-disc pl-6 text-gray-600 dark:text-gray-300 space-y-2">
                <li><strong>Android:</strong> Settings → Google → Ads → Opt out of Ads Personalization</li>
                <li><strong>iOS:</strong> Settings → Privacy → Apple Advertising → Turn off Personalized Ads</li>
              </ul>
              <p className="text-gray-600 dark:text-gray-300 mt-4">
                Premium subscribers do not see advertisements.
              </p>
            </section>

            <section className="mb-8">
              <h2 className="text-xl font-semibold text-gray-900 dark:text-white mb-4">5. Data Sharing</h2>
              <p className="text-gray-600 dark:text-gray-300 mb-2">We do not sell your personal information. We may share your information with:</p>
              <ul className="list-disc pl-6 text-gray-600 dark:text-gray-300 space-y-2">
                <li><strong>Service Providers:</strong> Third-party companies that help us operate the App (analytics, crash reporting, advertising).</li>
                <li><strong>Legal Requirements:</strong> If required by law or to protect our rights.</li>
                <li><strong>Business Transfers:</strong> In connection with a merger, acquisition, or sale of assets.</li>
              </ul>
            </section>

            <section className="mb-8">
              <h2 className="text-xl font-semibold text-gray-900 dark:text-white mb-4">6. Data Retention</h2>
              <p className="text-gray-600 dark:text-gray-300">
                We retain your personal information for as long as your account is active or as needed to provide
                you services. You can request deletion of your account and associated data by contacting us at{' '}
                <a href={`mailto:${contactEmail}`} className="text-primary-600 hover:underline">{contactEmail}</a>.
              </p>
            </section>

            <section className="mb-8">
              <h2 className="text-xl font-semibold text-gray-900 dark:text-white mb-4">7. Data Security</h2>
              <p className="text-gray-600 dark:text-gray-300">
                We implement appropriate technical and organizational measures to protect your personal information
                against unauthorized access, alteration, disclosure, or destruction. However, no method of
                transmission over the Internet or electronic storage is 100% secure.
              </p>
            </section>

            <section className="mb-8">
              <h2 className="text-xl font-semibold text-gray-900 dark:text-white mb-4">8. Children's Privacy</h2>
              <p className="text-gray-600 dark:text-gray-300">
                Our App is not directed to children under 13. We do not knowingly collect personal information
                from children under 13. If you are a parent or guardian and believe your child has provided us
                with personal information, please contact us at{' '}
                <a href={`mailto:${contactEmail}`} className="text-primary-600 hover:underline">{contactEmail}</a>.
              </p>
            </section>

            <section className="mb-8">
              <h2 className="text-xl font-semibold text-gray-900 dark:text-white mb-4">9. Your Rights</h2>
              <p className="text-gray-600 dark:text-gray-300 mb-2">Depending on your location, you may have the right to:</p>
              <ul className="list-disc pl-6 text-gray-600 dark:text-gray-300 space-y-2">
                <li>Access the personal information we hold about you</li>
                <li>Request correction of inaccurate information</li>
                <li>Request deletion of your information</li>
                <li>Object to or restrict processing of your information</li>
                <li>Data portability</li>
                <li>Withdraw consent at any time</li>
              </ul>
              <p className="text-gray-600 dark:text-gray-300 mt-4">
                To exercise these rights, contact us at{' '}
                <a href={`mailto:${contactEmail}`} className="text-primary-600 hover:underline">{contactEmail}</a>.
              </p>
            </section>

            <section className="mb-8">
              <h2 className="text-xl font-semibold text-gray-900 dark:text-white mb-4">10. Changes to This Policy</h2>
              <p className="text-gray-600 dark:text-gray-300">
                We may update this Privacy Policy from time to time. We will notify you of any changes by posting
                the new Privacy Policy in the App and updating the "Last updated" date. You are advised to review
                this Privacy Policy periodically for any changes.
              </p>
            </section>

            <section className="mb-8">
              <h2 className="text-xl font-semibold text-gray-900 dark:text-white mb-4">11. Contact Us</h2>
              <p className="text-gray-600 dark:text-gray-300">
                If you have any questions about this Privacy Policy, please contact us:
              </p>
              <ul className="list-none mt-4 text-gray-600 dark:text-gray-300 space-y-2">
                <li><strong>Email:</strong> <a href={`mailto:${contactEmail}`} className="text-primary-600 hover:underline">{contactEmail}</a></li>
                <li><strong>Developer:</strong> DBK Games</li>
              </ul>
            </section>
          </div>
        </div>
      </main>

      {/* Footer */}
      <footer className="max-w-4xl mx-auto px-4 py-8 text-center text-sm text-gray-500 dark:text-gray-400">
        <p>&copy; {new Date().getFullYear()} DBK Games. All rights reserved.</p>
        <div className="mt-2 space-x-4">
          <Link to="/terms" className="hover:text-primary-600">Terms of Service</Link>
          <Link to="/support" className="hover:text-primary-600">Support</Link>
        </div>
      </footer>
    </div>
  )
}
