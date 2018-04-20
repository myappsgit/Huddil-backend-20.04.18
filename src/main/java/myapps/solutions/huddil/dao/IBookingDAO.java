package myapps.solutions.huddil.dao;

import java.io.IOException;
import java.net.URISyntaxException;
import java.util.Date;
import java.util.List;
import java.util.Optional;

import javax.mail.MessagingException;
import javax.mail.internet.AddressException;

import org.apache.http.client.ClientProtocolException;

import myapps.solutions.huddil.model.BookingCost;
import myapps.solutions.huddil.model.BookingResultsPagination;
import myapps.solutions.huddil.model.BookingView;
import myapps.solutions.huddil.model.BookingViewPagination;
import myapps.solutions.huddil.model.CalendarBookingDetails;
import myapps.solutions.huddil.model.CancellationResults;
import myapps.solutions.huddil.model.JobData;
import myapps.solutions.huddil.model.LeastCost;
import myapps.solutions.huddil.model.SpBookingStatus;
import myapps.solutions.huddil.model.UpdateBooking;

public interface IBookingDAO {

	BookingViewPagination bookingFilter(String sessionId, int cityId, int localityId, int month, int status, int typeId, int pageNo, int count);
	List<BookingView> getBooking(String sessionId, int bookingId, Optional<Integer> facilityType, Optional<Integer> city, Optional<Integer> locality, Optional<Integer> month, Optional<Integer> status);
	BookingViewPagination getBookings(String sessionId, String emailId, int pageNo, int count);
	BookingResultsPagination getBookingsByConsumer(String sessionId, int count, int pageNo);
	BookingResultsPagination getBookingsHistoryByConsumer(String sessionId, int count, int pageNo);
	BookingResultsPagination getBookingsCancellationByConsumer(String sessionId, int count, int pageNo);
	CancellationResults getCancellationDetails(String sessionId, int id);
	BookingView getCompletedBookingDetails(String sessionId, int id);
	BookingViewPagination getBookingsCancellationBySP(String sessionId, int cityId, int localityId, int month, int status, int typeId, int pageNo, int count);
	BookingViewPagination getBlockedTimings(String sessionId, int status, int facilityId, int pageNo, int count);
	

	UpdateBooking updateBookingStatusBySP(String sessionId, int bookingId, boolean status, boolean confirm) throws AddressException, IOException, MessagingException;
	List<SpBookingStatus> getBookingStatus(String sessionId);

	public BookingCost calculateOrBook(Date fromTime, Date toTime, int capacity, int facilityId, String sessionId,
			int operation, String paymentMethod, String paymentId, int bookingId, String redirectUrl)
			throws ClientProtocolException, IOException, URISyntaxException, MessagingException;
	List<JobData> getNextJob(boolean sendMail);
	void moveCompleteBooking(String bookingId);
	CalendarBookingDetails calendarBookings(Date fromTime, int facilityId);
	List<LeastCost> leastCost(boolean populate);
	void deleteOffersaddCommission();
	int updateCompletedBookingBySP(String sessionId, int id);
	
}
