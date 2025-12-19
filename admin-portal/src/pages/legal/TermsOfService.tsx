import { Link } from 'react-router-dom'
import { Puzzle, ArrowLeft } from 'lucide-react'

export default function TermsOfService() {
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
              <p className="text-xs text-gray-500 dark:text-gray-400">Terms of Service</p>
            </div>
          </div>
        </div>
      </header>

      {/* Content */}
      <main className="max-w-4xl mx-auto px-4 py-8">
        <div className="bg-white dark:bg-gray-800 rounded-2xl shadow-sm p-8">
          <h1 className="text-3xl font-bold text-gray-900 dark:text-white mb-2">Terms of Service</h1>
          <p className="text-sm text-gray-500 dark:text-gray-400 mb-8">Last updated: {lastUpdated}</p>

          <div className="prose dark:prose-invert max-w-none">
            <section className="mb-8">
              <h2 className="text-xl font-semibold text-gray-900 dark:text-white mb-4">1. Acceptance of Terms</h2>
              <p className="text-gray-600 dark:text-gray-300 mb-4">
                By downloading, installing, or using The Dailies mobile application ("App"), you agree to be bound
                by these Terms of Service ("Terms"). If you do not agree to these Terms, do not use the App.
              </p>
              <p className="text-gray-600 dark:text-gray-300">
                These Terms constitute a legally binding agreement between you and DBK Games ("we," "our," or "us")
                regarding your use of the App.
              </p>
            </section>

            <section className="mb-8">
              <h2 className="text-xl font-semibold text-gray-900 dark:text-white mb-4">2. Description of Service</h2>
              <p className="text-gray-600 dark:text-gray-300 mb-4">
                The Dailies is a mobile puzzle game application that provides daily puzzles including Sudoku,
                Killer Sudoku, Crossword, and Word Search games. The App is available as a free version with
                advertisements and a premium subscription option.
              </p>
            </section>

            <section className="mb-8">
              <h2 className="text-xl font-semibold text-gray-900 dark:text-white mb-4">3. User Accounts</h2>
              <p className="text-gray-600 dark:text-gray-300 mb-4">
                Some features of the App may require you to create an account. You are responsible for:
              </p>
              <ul className="list-disc pl-6 text-gray-600 dark:text-gray-300 space-y-2">
                <li>Providing accurate and complete information</li>
                <li>Maintaining the security of your account credentials</li>
                <li>All activities that occur under your account</li>
                <li>Notifying us immediately of any unauthorized use</li>
              </ul>
              <p className="text-gray-600 dark:text-gray-300 mt-4">
                We reserve the right to suspend or terminate accounts that violate these Terms.
              </p>
            </section>

            <section className="mb-8">
              <h2 className="text-xl font-semibold text-gray-900 dark:text-white mb-4">4. Subscriptions and Purchases</h2>

              <h3 className="text-lg font-medium text-gray-800 dark:text-gray-200 mb-2">4.1 Premium Subscription</h3>
              <p className="text-gray-600 dark:text-gray-300 mb-4">
                The App offers a premium subscription that provides an ad-free experience, unlimited hints,
                and access to the puzzle archive. Subscription details:
              </p>
              <ul className="list-disc pl-6 text-gray-600 dark:text-gray-300 mb-4 space-y-2">
                <li>Price: $1.99 USD per month (prices may vary by region)</li>
                <li>Free trial: 3 days for first-time subscribers</li>
                <li>Billing cycle: Monthly, automatically renewed</li>
              </ul>

              <h3 className="text-lg font-medium text-gray-800 dark:text-gray-200 mb-2">4.2 Billing</h3>
              <p className="text-gray-600 dark:text-gray-300 mb-4">
                Subscriptions are billed through the Google Play Store or Apple App Store. Payment will be
                charged to your account upon confirmation of purchase. Subscriptions automatically renew
                unless auto-renew is turned off at least 24 hours before the end of the current period.
              </p>

              <h3 className="text-lg font-medium text-gray-800 dark:text-gray-200 mb-2">4.3 Cancellation</h3>
              <p className="text-gray-600 dark:text-gray-300 mb-4">
                You may cancel your subscription at any time through your device's subscription settings:
              </p>
              <ul className="list-disc pl-6 text-gray-600 dark:text-gray-300 space-y-2">
                <li><strong>Android:</strong> Google Play Store → Subscriptions → The Dailies → Cancel</li>
                <li><strong>iOS:</strong> Settings → Apple ID → Subscriptions → The Dailies → Cancel</li>
              </ul>
              <p className="text-gray-600 dark:text-gray-300 mt-4">
                Cancellation takes effect at the end of the current billing period. No refunds are provided
                for partial subscription periods.
              </p>

              <h3 className="text-lg font-medium text-gray-800 dark:text-gray-200 mb-2">4.4 Free Trial</h3>
              <p className="text-gray-600 dark:text-gray-300">
                If you start a free trial and do not cancel before the trial ends, you will be automatically
                charged the subscription fee. Free trials are limited to one per user/device.
              </p>
            </section>

            <section className="mb-8">
              <h2 className="text-xl font-semibold text-gray-900 dark:text-white mb-4">5. Acceptable Use</h2>
              <p className="text-gray-600 dark:text-gray-300 mb-2">You agree not to:</p>
              <ul className="list-disc pl-6 text-gray-600 dark:text-gray-300 space-y-2">
                <li>Use the App for any unlawful purpose</li>
                <li>Attempt to gain unauthorized access to our systems</li>
                <li>Interfere with or disrupt the App's functionality</li>
                <li>Reverse engineer, decompile, or disassemble the App</li>
                <li>Use cheats, exploits, or automation software</li>
                <li>Create multiple accounts to abuse free trials or tokens</li>
                <li>Share your account credentials with others</li>
                <li>Use the App to harass, abuse, or harm others</li>
              </ul>
            </section>

            <section className="mb-8">
              <h2 className="text-xl font-semibold text-gray-900 dark:text-white mb-4">6. Intellectual Property</h2>
              <p className="text-gray-600 dark:text-gray-300 mb-4">
                The App and its original content, features, and functionality are owned by DBK Games and are
                protected by international copyright, trademark, and other intellectual property laws.
              </p>
              <p className="text-gray-600 dark:text-gray-300">
                You are granted a limited, non-exclusive, non-transferable license to use the App for personal,
                non-commercial purposes in accordance with these Terms.
              </p>
            </section>

            <section className="mb-8">
              <h2 className="text-xl font-semibold text-gray-900 dark:text-white mb-4">7. Advertisements</h2>
              <p className="text-gray-600 dark:text-gray-300">
                The free version of the App displays advertisements provided by third-party ad networks.
                We are not responsible for the content of third-party advertisements. By using the free
                version, you consent to receiving these advertisements.
              </p>
            </section>

            <section className="mb-8">
              <h2 className="text-xl font-semibold text-gray-900 dark:text-white mb-4">8. Disclaimer of Warranties</h2>
              <p className="text-gray-600 dark:text-gray-300 mb-4">
                THE APP IS PROVIDED "AS IS" AND "AS AVAILABLE" WITHOUT WARRANTIES OF ANY KIND, EITHER EXPRESS
                OR IMPLIED, INCLUDING BUT NOT LIMITED TO IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A
                PARTICULAR PURPOSE, AND NON-INFRINGEMENT.
              </p>
              <p className="text-gray-600 dark:text-gray-300">
                We do not warrant that the App will be uninterrupted, error-free, or free of viruses or other
                harmful components.
              </p>
            </section>

            <section className="mb-8">
              <h2 className="text-xl font-semibold text-gray-900 dark:text-white mb-4">9. Limitation of Liability</h2>
              <p className="text-gray-600 dark:text-gray-300">
                TO THE MAXIMUM EXTENT PERMITTED BY LAW, DBK GAMES SHALL NOT BE LIABLE FOR ANY INDIRECT,
                INCIDENTAL, SPECIAL, CONSEQUENTIAL, OR PUNITIVE DAMAGES, INCLUDING BUT NOT LIMITED TO LOSS
                OF PROFITS, DATA, OR USE, ARISING OUT OF OR IN CONNECTION WITH YOUR USE OF THE APP.
              </p>
            </section>

            <section className="mb-8">
              <h2 className="text-xl font-semibold text-gray-900 dark:text-white mb-4">10. Indemnification</h2>
              <p className="text-gray-600 dark:text-gray-300">
                You agree to indemnify and hold harmless DBK Games and its officers, directors, employees,
                and agents from any claims, damages, losses, liabilities, and expenses (including legal fees)
                arising out of your use of the App or violation of these Terms.
              </p>
            </section>

            <section className="mb-8">
              <h2 className="text-xl font-semibold text-gray-900 dark:text-white mb-4">11. Modifications to the App</h2>
              <p className="text-gray-600 dark:text-gray-300">
                We reserve the right to modify, suspend, or discontinue the App (or any part thereof) at any
                time with or without notice. We shall not be liable to you or any third party for any
                modification, suspension, or discontinuance of the App.
              </p>
            </section>

            <section className="mb-8">
              <h2 className="text-xl font-semibold text-gray-900 dark:text-white mb-4">12. Changes to Terms</h2>
              <p className="text-gray-600 dark:text-gray-300">
                We may revise these Terms at any time by updating this page. Your continued use of the App
                after any changes constitutes acceptance of the new Terms. We encourage you to periodically
                review these Terms.
              </p>
            </section>

            <section className="mb-8">
              <h2 className="text-xl font-semibold text-gray-900 dark:text-white mb-4">13. Governing Law</h2>
              <p className="text-gray-600 dark:text-gray-300">
                These Terms shall be governed by and construed in accordance with the laws of South Africa,
                without regard to its conflict of law provisions.
              </p>
            </section>

            <section className="mb-8">
              <h2 className="text-xl font-semibold text-gray-900 dark:text-white mb-4">14. Contact Us</h2>
              <p className="text-gray-600 dark:text-gray-300">
                If you have any questions about these Terms, please contact us:
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
          <Link to="/privacy" className="hover:text-primary-600">Privacy Policy</Link>
          <Link to="/support" className="hover:text-primary-600">Support</Link>
        </div>
      </footer>
    </div>
  )
}
